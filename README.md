# moamoa-nft
## What should go into a .env file?
Your .env file should contain environment variables such as contract addresses required for your application.
<br><br>
<b>Here’s an example:</b>
```
FAM_CONTRACT_ADDRESS=YOUR_FAM_CONTRACT_ADDRESS
NFT_CONTRACT_ADDRESS=YOUR_NFT_CONTRACT_ADDRESS
NFT_SHARE_CONTRACT_ADDRESS=YOUR_NFT_SHARE_CONTRACT_ADDRESS
```

## How to use Docker
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