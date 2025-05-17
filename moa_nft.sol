// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC1155/extensions/ERC1155Burnable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/Base64.sol";

// NFT 공유 컨트랙트 인터페이스
interface INFTSharing {
    function shareNFT(uint256 tokenId, address to) external;
    function revokeNFTSharing(uint256 tokenId, address from) external;
    function getSharedWith(uint256 tokenId) external view returns (address[] memory);
}

contract moa_nft is ERC1155Burnable, Ownable, ReentrancyGuard {
    using Strings for uint256;

    // 현재 발행된 토큰 ID
    uint256 private _currentTokenID = 0;
    // 최대 토큰 ID 제한
    uint256 private constant MAX_TOKEN_ID = 1000000;
    // NFT 공유 컨트랙트 주소
    address private _nftSharingContractAddress;

    // 토큰 정보 및 메타데이터 구조체
    struct TokenMetadata {
        string name;           // 토큰 이름
        string description;    // 토큰 설명
        string image;          // 이미지 데이터 (base64 또는 SVG)
        address creator;       // 생성자 주소
        uint256 createdAt;     // 생성 시간
        uint256 updatedAt;     // 업데이트 시간
    }

    // 토큰 ID -> 토큰 메타데이터 매핑
    mapping(uint256 => TokenMetadata) private _tokenMetadata;
    // 토큰 존재 여부 체크
    mapping(uint256 => bool) private _tokenExists;

    event TokenCreated(uint256 indexed tokenId, address indexed creator);
    event MetadataUpdated(uint256 indexed tokenId);
    event NFTSharingContractUpdated(address indexed oldAddress, address indexed newAddress);

    constructor() ERC1155("") Ownable(msg.sender) {
        
    }
    
    // NFT 공유 컨트랙트 주소 설정
    function setNFTSharingContract(address sharingContract) external onlyOwner {
        address oldAddress = _nftSharingContractAddress;
        _nftSharingContractAddress = sharingContract;
        emit NFTSharingContractUpdated(oldAddress, sharingContract);
    }
    
    // NFT 공유 컨트랙트 주소 조회
    function getNFTSharingContract() external view returns (address) {
        return _nftSharingContractAddress;
    }

    function mint(
        string memory _name,
        string memory _description,
        string memory _image
    ) external nonReentrant {
        uint256 tokenId = _currentTokenID;
        require(tokenId < MAX_TOKEN_ID, "Token ID limit reached");
        require(bytes(_name).length > 0, "Name cannot be empty");
        require(bytes(_image).length > 0, "Image cannot be empty");

        // 토큰 발행
        _mint(msg.sender, tokenId, 1, "");  

        // 메타데이터 설정
        _tokenMetadata[tokenId].name = _name;
        _tokenMetadata[tokenId].description = _description;
        _tokenMetadata[tokenId].image = _image;
        _tokenMetadata[tokenId].creator = msg.sender;
        _tokenMetadata[tokenId].createdAt = block.timestamp;
        _tokenMetadata[tokenId].updatedAt = block.timestamp;

        _tokenExists[tokenId] = true;
        _currentTokenID++;

        emit TokenCreated(tokenId, msg.sender);
    }

    // URI 반환 - 온체인 메타데이터를 JSON 형식으로 인코딩
    function uri(uint256 tokenId) public view override returns (string memory) {
        require(_tokenExists[tokenId], "Token does not exist");
        
        // JSON 메타데이터 생성
        string memory json = _generateJSON(tokenId);
        
        // Base64로 인코딩하여 data URI 형식으로 반환
        return string(
            abi.encodePacked(
                "data:application/json;base64,",
                Base64.encode(bytes(json))
            )
        );
    }

    // JSON 메타데이터 생성
    function _generateJSON(uint256 tokenId) internal view returns (string memory) {
        TokenMetadata storage metadata = _tokenMetadata[tokenId];
        
        
        string memory json = string(
            abi.encodePacked(
                '{',
                '"name": "', metadata.name, '",',
                '"description": "', metadata.description, '",',
                '"image": "', metadata.image, '",',
                '"creator": "', _addressToString(metadata.creator), '",',
                '"created_at": ', _uint256ToString(metadata.createdAt), ',',
                '"updated_at": ', _uint256ToString(metadata.updatedAt),
                '}'
            )
        );
        
        return json;
    }

    // 메타데이터 업데이트
    function updateMetadata(
        uint256 tokenId,
        string memory _name,
        string memory _description,
        string memory _image
    ) external nonReentrant {
        require(_tokenExists[tokenId], "Token does not exist");
        require(msg.sender == _tokenMetadata[tokenId].creator, "Not the creator of this token");
        
        if (bytes(_name).length > 0) {
            _tokenMetadata[tokenId].name = _name;
        }
        
        if (bytes(_description).length > 0) {
            _tokenMetadata[tokenId].description = _description;
        }
        
        if (bytes(_image).length > 0) {
            _tokenMetadata[tokenId].image = _image;
        }
        
        _tokenMetadata[tokenId].updatedAt = block.timestamp;

        emit MetadataUpdated(tokenId);
    }
    
    // 메타데이터 업데이트와 공유 상태 변경을 한 번에 처리하는 함수
    function updateMetadataAndSharing(
        uint256 tokenId,
        string memory _name,
        string memory _description,
        string memory _image,
        address[] memory addSharing,    // 새로 공유할 주소 목록
        address[] memory removeSharing  // 공유 취소할 주소 목록
    ) external nonReentrant {
        require(_tokenExists[tokenId], "Token does not exist");
        require(msg.sender == _tokenMetadata[tokenId].creator, "Not the creator of this token");
        require(_nftSharingContractAddress != address(0), "NFT Sharing contract not set");
        
        // 메타데이터 업데이트
        if (bytes(_name).length > 0) {
            _tokenMetadata[tokenId].name = _name;
        }
        
        if (bytes(_description).length > 0) {
            _tokenMetadata[tokenId].description = _description;
        }
        
        if (bytes(_image).length > 0) {
            _tokenMetadata[tokenId].image = _image;
        }
        
        _tokenMetadata[tokenId].updatedAt = block.timestamp;
        
        // NFT 공유 컨트랙트 인스턴스
        INFTSharing nftSharing = INFTSharing(_nftSharingContractAddress);
        
        // 새로 공유할 주소 처리
        for (uint i = 0; i < addSharing.length; i++) {
            address to = addSharing[i];
            if (to != address(0) && to != msg.sender) {
                try nftSharing.shareNFT(tokenId, to) {
                    // 성공적으로 공유됨
                } catch {
                    // 실패해도 계속 진행 (이미 공유된 경우 등)
                }
            }
        }
        
        // 공유 취소할 주소 처리
        for (uint i = 0; i < removeSharing.length; i++) {
            address from = removeSharing[i];
            if (from != address(0)) {
                try nftSharing.revokeNFTSharing(tokenId, from) {
                    // 성공적으로 공유 취소됨
                } catch {
                    // 실패해도 계속 진행 (이미 공유 취소된 경우 등)
                }
            }
        }
        
        emit MetadataUpdated(tokenId);
    }

    // 토큰 정보 조회 
    function getTokenInfo(uint256 tokenId) external view returns (
        string memory name,
        string memory description,
        address creator,
        uint256 createdAt,
        uint256 updatedAt
    ) {
        require(_tokenExists[tokenId], "Token does not exist");
        TokenMetadata storage metadata = _tokenMetadata[tokenId];
        
        return (
            metadata.name,
            metadata.description,
            metadata.creator,
            metadata.createdAt,
            metadata.updatedAt
        );
    }

    // 토큰 존재 여부 확인
    function exists(uint256 tokenId) external view returns (bool) {
        return _tokenExists[tokenId];
    }

    // 유틸리티 함수: uint256을 string으로 변환
    function _uint256ToString(uint256 value) internal pure returns (string memory) {
        return value.toString();
    }

    // 유틸리티 함수: address를 string으로 변환
    function _addressToString(address addr) internal pure returns (string memory) {
        return Strings.toHexString(uint256(uint160(addr)), 20);
    }
}
