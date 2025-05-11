# moamoa-nft
## Index
### Main features
[1. 가족 등록 및 관리](#가족-등록-및-관리-기능)<br>
[2. NFT 발행](#nft-발행minting-기능)<br>
[3. NFT 가족 공유](#nft-가족-공유-기능)<br>

### How to use
[.env](#what-should-go-into-a-env-file)<br>
[Docker](#how-to-use-docker)<br>

## Main features
[-> 프로젝트 실행 영상](https://www.youtube.com/watch?v=_Gd4pED8VK8)

### 가족 등록 및 관리 기능
`addFamilyMember` 함수를 통해 사용자는 다른 지갑 주소를 가족으로 등록할 수 있습니다. 등록 시 양방향 가족 관계가 형성되고, 각자 원하는 닉네임을 설정할 수 있습니다. 가족 해제, 닉네임 변경, 가족 목록 조회 등도 지원되어, 블록체인 상에서 가족 관계를 안전하게 관리할 수 있습니다
<br><br>
With the `addFamilyMember` function, a user can register another wallet address as a family member. This creates a bi-directional family relationship and allows both parties to set their preferred nicknames. The contract also supports removing family members, changing nicknames, and viewing the family list, enabling secure management of family relationships on the blockchain

### NFT 발행(Minting) 기능
사용자는 `mint` 함수를 통해 자신만의 이름, 설명, 이미지를 가진 새로운 NFT(ERC-1155 토큰)를 발행할 수 있습니다. 발행 시 메타데이터(이름, 설명, 이미지, 생성자, 생성/수정 시각 등)가 온체인에 저장되며, 토큰의 고유 ID가 자동으로 증가합니다. 이 기능은 누구나 손쉽게 자신만의 NFT를 만들 수 있도록 합니다
<br><br>
Users can mint a new NFT (ERC-1155 token) with a custom name, description, and image using the mint function. Metadata such as name, description, image, creator address, and timestamps are stored on-chain, and the unique token ID is automatically incremented. This feature enables anyone to easily create their own NFT

### NFT 가족 공유 기능
`shareNFT` 함수를 사용하면 NFT 소유자가 특정 가족 구성원과 자신의 NFT를 공유할 수 있습니다. 이 기능은 가족 관리 컨트랙트와 연동되어, 가족 관계가 있는 사용자에게만 NFT 열람 권한을 부여합니다. 공유된 NFT는 언제든 공유 취소가 가능하며, 공유 내역 조회 및 권한 확인도 지원합니다
<br><br>
Using the `shareNFT` function, an NFT owner can share their NFT with a specific family member. This feature integrates with the family management contract to ensure that only users with a family relationship can be granted viewing rights to the NFT. Shared NFTs can have their sharing revoked at any time, and the contract supports querying sharing history and checking access permissions

## How to use

### What should go into a .env file?
Your .env file should contain environment variables such as contract addresses required for your application.
<br><br>
<b>Here’s an example:</b>
```
FAM_CONTRACT_ADDRESS=YOUR_FAM_CONTRACT_ADDRESS
NFT_CONTRACT_ADDRESS=YOUR_NFT_CONTRACT_ADDRESS
NFT_SHARE_CONTRACT_ADDRESS=YOUR_NFT_SHARE_CONTRACT_ADDRESS
```

### How to use Docker
```
# Build a Docker image
docker build -t (image_name) .

# Run a container from the image
docker run -it --name (container_name) (image_name)
```
<b>Tips:</b>
<br>
Replace `(image_name)` and `(container_name)` with your desired names.
<br><br>
Make sure your .env file is in the project root directory before building the Docker image if your application depends on environment variables.