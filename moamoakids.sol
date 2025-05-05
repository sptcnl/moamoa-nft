// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

// OpenZeppelin 라이브러리 불러오기
import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract MoamoaKids is ERC1155, Ownable {
    // 가족 여부를 저장하는 매핑 (A -> B)
    mapping(address => mapping(address => bool)) private familyRelations;
    // 닉네임 저장 (개인 주소별)
    mapping(address => string) private familyNicknames;
    // 각 지갑이 등록한 가족 목록
    mapping(address => address[]) private myFamilyList;

    // 이벤트들
    event FamilyMemberAdded(address indexed owner, address indexed member, string nickname);
    event FamilyMemberRemoved(address indexed owner, address indexed member);
    event FamilyNicknameChanged(address indexed member, string newNickname);

    // 생성자
    constructor(string memory uri) ERC1155(uri) Ownable(msg.sender) {
        // 배포자는 기본 닉네임 설정
        familyNicknames[msg.sender] = "Me";
    }

    // 가족 등록 (양방향 등록)
    function addFamilyMember(address member, string memory myNickname, string memory memberNickname) external {
        require(member != msg.sender, "Cannot add yourself as family.");
        require(!familyRelations[msg.sender][member], "Already family.");

        // 양방향 가족 등록
        familyRelations[msg.sender][member] = true;
        familyRelations[member][msg.sender] = true;

        // 가족 리스트 추가
        myFamilyList[msg.sender].push(member);
        myFamilyList[member].push(msg.sender);

        // 닉네임 설정
        if (bytes(familyNicknames[msg.sender]).length == 0) {
            familyNicknames[msg.sender] = myNickname;
        }
        if (bytes(familyNicknames[member]).length == 0) {
            familyNicknames[member] = memberNickname;
        }

        emit FamilyMemberAdded(msg.sender, member, memberNickname);
    }

    // 가족 해제 (양방향 삭제)
    function removeFamilyMember(address member) external {
        require(familyRelations[msg.sender][member], "Not registered as family.");

        // 양방향 관계 끊기
        familyRelations[msg.sender][member] = false;
        familyRelations[member][msg.sender] = false;

        // 가족 리스트에서 제거 (sender 입장)
        _removeFromFamilyList(msg.sender, member);
        // 가족 리스트에서 제거 (상대방 입장)
        _removeFromFamilyList(member, msg.sender);

        emit FamilyMemberRemoved(msg.sender, member);
    }

    // 닉네임 변경
    function setMyNickname(string memory newNickname) external {
        familyNicknames[msg.sender] = newNickname;
        emit FamilyNicknameChanged(msg.sender, newNickname);
    }

    // 가족 목록 조회
    function getMyFamilyMembers() external view returns (address[] memory) {
        return myFamilyList[msg.sender];
    }

    // 내 닉네임 조회
    function getMyNickname() external view returns (string memory) {
        return familyNicknames[msg.sender];
    }

    // 특정 주소의 닉네임 조회
    function getNickname(address member) external view returns (string memory) {
        return familyNicknames[member];
    }

    // 가족 여부 확인
    function isMyFamily(address member) external view returns (bool) {
        return familyRelations[msg.sender][member];
    }

    // 내부 함수: 리스트에서 주소 제거
    function _removeFromFamilyList(address owner, address member) internal {
        address[] storage list = myFamilyList[owner];
        for (uint i = 0; i < list.length; i++) {
            if (list[i] == member) {
                list[i] = list[list.length - 1];
                list.pop();
                break;
            }
        }
    }
}
