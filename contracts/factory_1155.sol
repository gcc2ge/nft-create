pragma solidity 0.8.9;

import "./NFT_1155.sol";
import "interfaces/ifactory_1155.sol";

import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";

contract Factory1155 is IFactory_1155, AccessControl {
    event CreateNFT1155(address tokenAddress);
    event SignerUpdated(address newSigner);

    using ECDSA for bytes32;

    address private _signer;

    bytes32 public constant OPERATOR_ROLE = keccak256("OPERATOR_ROLE");
    bytes32 public constant MINT_ROLE = keccak256("MINT_ROLE");

    constructor(address _initialSigner) {
        _signer = _initialSigner;

        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _setupRole(OPERATOR_ROLE, msg.sender);
        _setupRole(MINT_ROLE, msg.sender);
    }

    function setSigner(address _newSigner) public onlyRole(OPERATOR_ROLE) {
        _signer = _newSigner;

        emit SignerUpdated(_signer);
    }

    function grantOperatorRole(address to) public {
        grantRole(OPERATOR_ROLE, to);
    }

    function reovkeOperatorRole(address to) public {
        revokeRole(OPERATOR_ROLE, to);
    }

    function grantMintRole(address to) public {
        grantRole(MINT_ROLE, to);
    }

    function reovkeMintRole(address to) public {
        revokeRole(MINT_ROLE, to);
    }

    function _hash(
        string memory _name,
        string memory _symbol,
        string memory _ipfs_uri,
        string memory _me_uri,
        string memory _salt
    ) internal view returns (bytes32) {
        return
            keccak256(
                abi.encodePacked(_name, _symbol, _ipfs_uri, _me_uri, _salt)
            );
    }

    function createToken(
        string memory _name,
        string memory _symbol,
        string memory _ipfs_uri,
        string memory _me_uri,
        string memory _salt,
        bytes memory _signature
    ) external returns (address) {
        bytes32 hash = _hash(_name, _symbol, _ipfs_uri, _me_uri, _salt);
        bytes32 message = hash.toEthSignedMessageHash();
        require(message.recover(_signature) == _signer, "error sig");

        NFT1155 token = new NFT1155(_name, _symbol, _ipfs_uri, _me_uri);

        address _tokenAddress = address(token);

        emit CreateNFT1155(_tokenAddress);

        return _tokenAddress;
    }

    function mint_1155(
        address nft1155,
        address receiver,
        string memory _tokenURI,
        uint256 quantities,
        uint256 token_type
    ) external onlyRole(MINT_ROLE) {
        NFT1155 token = NFT1155(nft1155);
        token.mint(receiver, _tokenURI, quantities, token_type);
    }

    function mintBatch_1155(
        address nft1155,
        address receiver,
        string[] memory _tokenURIs_batch,
        uint256[] calldata quantities,
        uint256[] calldata token_types
    ) external onlyRole(MINT_ROLE) {
        NFT1155 token = NFT1155(nft1155);
        token.mintBatch(receiver, _tokenURIs_batch, quantities, token_types);
    }
}
