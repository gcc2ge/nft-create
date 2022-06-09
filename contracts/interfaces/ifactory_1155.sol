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
        address _nft1155,
        address _receiver,
        uint256 _id,
        uint256 _quantities
    ) external;

    function mintBatch_1155(
        address _nft1155,
        address _receiver,
        uint256[] calldata _ids,
        uint256[] calldata _quantities
    ) external;
}
