// SPDX-License-Identifier: MIT LICENSE

pragma solidity ^0.8.0;

interface IFactory_721 {
    function createToken(
        string memory _name,
        string memory _symbol,
        string memory _ipfs_uri,
        string memory _me_uri,
        string memory _salt,
        bytes memory _signature
    ) external returns (address);

    function mint_721(address _nft721, address _to) external;

    function mintBatch_721(
        address _nft721,
        address _to,
        uint256 _quantity
    ) external;
}
