// SPDX-License-Identifier: MIT LICENSE

pragma solidity ^0.8.0;

interface IFactory_1155 {
    function createToken(
        string memory _name,
        string memory _symbol,
        string memory _ipfs_uri,
        string memory _me_uri,
        string memory _salt,
        bytes memory _signature
    ) external returns (address);

    function mint_1155(
        address nft1155,
        address receiver,
        string memory _tokenURI,
        uint256 quantities,
        uint256 token_type
    ) external;

    function mintBatch_1155(
        address nft1155,
        address receiver,
        string[] memory _tokenURIs_batch,
        uint256[] calldata quantities,
        uint256[] calldata token_types
    ) external;
}
