// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

// NFT 컨트랙트 인터페이스
interface INFT is IERC1155 {
    function exists(uint256 tokenId) external view returns (bool);
    function balanceOf(address account, uint256 id) external view returns (uint256);
}

// 가족 관리 컨트랙트 인터페이스
interface IFamilyManager {
    function isMyFamily(address member) external view returns (bool);
    function getMyFamilyMembers() external view returns (address[] memory);
}

/*
 * @title NFTSharing
 * @dev 가족 및 특정 사용자와 NFT를 공유할 수 있는 컨트랙트
 */
contract NFTSharing is Ownable, ReentrancyGuard {
    // NFT 컨트랙트 주소
    INFT public nftContract;
    
    // 가족 관리 컨트랙트 주소
    IFamilyManager public familyManager;
    
    // (토큰ID => (공유받은 주소 => 권한 여부)) 매핑
    mapping(uint256 => mapping(address => bool)) private _tokenAuthorized;
    
    // (주소 => 공유받은 토큰ID 목록) 매핑
    mapping(address => uint256[]) private _sharedWithAddress;
    
    // (토큰ID => 공유된 주소 목록) 매핑
    mapping(uint256 => address[]) private _tokenSharedWith;
    
    // 이벤트: NFT 공유
    event NFTShared(uint256 indexed tokenId, address indexed owner, address indexed sharedWith);
    // 이벤트: NFT 공유 취소
    event NFTSharingRevoked(uint256 indexed tokenId, address indexed owner, address indexed revokedFrom);
    
    // 생성자: NFT 컨트랙트와 가족 컨트랙트 주소 지정
    constructor(address _nftContract, address _familyManager) Ownable(msg.sender) {
        nftContract = INFT(_nftContract);
        familyManager = IFamilyManager(_familyManager);
    }
    
    /*
     * @dev NFT를 특정 주소와 공유 (POST /nft/:tokenId/share)
     * @param tokenId 공유할 토큰 ID
     * @param to 공유받을 주소(viewer)
     */
    function shareNFT(uint256 tokenId, address to) external nonReentrant {
        require(nftContract.exists(tokenId), unicode"토큰이 존재하지 않음"); // 토큰 존재 확인
        require(nftContract.balanceOf(msg.sender, tokenId) > 0, unicode"이 토큰의 소유자 아님"); // 소유자 확인
        require(to != msg.sender, unicode"자기 자신과 공유는 불가"); // 자기 자신 제외
        require(to != address(0), unicode"0주소와 공유는 불가"); // 0주소 제외
        
        // 가족 관계 확인 - familyManager의 isMyFamily 함수 사용
        require(familyManager.isMyFamily(to), unicode"가족 구성원에게만 공유할 수 있습니다");
        
        _tokenAuthorized[tokenId][to] = true;
        _addToSharedWithAddress(to, tokenId);
        _addToTokenSharedWith(tokenId, to);
        
        emit NFTShared(tokenId, msg.sender, to);
    }
    
    /*
     * @dev NFT 공유 취소 (DELETE /nft/:tokenId/share)
     * @param tokenId 공유 취소할 토큰 ID
     * @param from 공유 권한을 취소할 주소(viewer)
     */
    function revokeNFTSharing(uint256 tokenId, address from) external nonReentrant {
        require(nftContract.exists(tokenId), unicode"토큰이 존재하지 않음");
        require(nftContract.balanceOf(msg.sender, tokenId) > 0, unicode"이 토큰의 소유자 아님");
        
        _tokenAuthorized[tokenId][from] = false;
        _removeFromSharedWithAddress(from, tokenId);
        _removeFromTokenSharedWith(tokenId, from);
        
        emit NFTSharingRevoked(tokenId, msg.sender, from);
    }
    
    /*
     * @dev 해당 토큰의 공유된 전체 주소 목록 조회 (GET /nft/:tokenId/authorized)
     * @param tokenId 조회할 토큰 ID
     * @return 공유된 주소 배열
     */
    function getSharedWith(uint256 tokenId) external view returns (address[] memory) {
        require(nftContract.balanceOf(msg.sender, tokenId) > 0, unicode"이 토큰의 소유자 아님");
        return _tokenSharedWith[tokenId];
    }
    
    /*
     * @dev 특정 주소의 열람 권한 확인 (GET /nft/:tokenId/isAuthorized)
     * @param tokenId 토큰 ID
     * @param viewer 확인할 주소(viewer)
     * @return bool 권한 여부 (true/false)
     */
    function isAuthorized(uint256 tokenId, address viewer) external view returns (bool) {
        if (nftContract.balanceOf(viewer, tokenId) > 0) {
            return true; // 소유자는 항상 권한 있음
        }
        return _tokenAuthorized[tokenId][viewer];
    }
    
    // (내가 공유받은) 토큰ID 전체 조회
    function getAuthorized() external view returns (uint256[] memory) {
        return _sharedWithAddress[msg.sender];
    }
    
    // 내부 함수: 주소별 공유받은 토큰ID 추가
    function _addToSharedWithAddress(address user, uint256 tokenId) internal {
        uint256[] storage tokens = _sharedWithAddress[user];
        for (uint i = 0; i < tokens.length; i++) {
            if (tokens[i] == tokenId) return; // 이미 있으면 추가 안함
        }
        tokens.push(tokenId);
    }
    
    // 내부 함수: 토큰ID별 공유된 주소 추가
    function _addToTokenSharedWith(uint256 tokenId, address user) internal {
        address[] storage users = _tokenSharedWith[tokenId];
        for (uint i = 0; i < users.length; i++) {
            if (users[i] == user) return; // 이미 있으면 추가 안함
        }
        users.push(user);
    }
    
    // 내부 함수: 주소별 공유받은 토큰ID 제거
    function _removeFromSharedWithAddress(address user, uint256 tokenId) internal {
        uint256[] storage tokens = _sharedWithAddress[user];
        for (uint i = 0; i < tokens.length; i++) {
            if (tokens[i] == tokenId) {
                tokens[i] = tokens[tokens.length - 1];
                tokens.pop();
                break;
            }
        }
    }
    
    // 내부 함수: 토큰ID별 공유된 주소 제거
    function _removeFromTokenSharedWith(uint256 tokenId, address user) internal {
        address[] storage users = _tokenSharedWith[tokenId];
        for (uint i = 0; i < users.length; i++) {
            if (users[i] == user) {
                users[i] = users[users.length - 1];
                users.pop();
                break;
            }
        }
    }
}