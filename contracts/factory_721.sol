pragma solidity 0.8.9;

import "./NFT_721.sol";
import "interfaces/ifactory_721.sol";

import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";

contract Factory721 is IFactory_721, AccessControl {
    event CreateNFT721(address tokenAddress);

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

    function reovkeMinterRole(address to) public {
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

        NFT721 token = new NFT721(_name, _symbol, _ipfs_uri, _me_uri);

        address _tokenAddress = address(token);

        emit CreateNFT721(_tokenAddress);

        return _tokenAddress;
    }

    function mint_721(
        address nft721,
        address _to,
        string memory _tokenURI,
        uint256 token_type
    ) external onlyRole(MINT_ROLE) {
        NFT721 token = NFT721(nft721);
        token.mint(_to, _tokenURI, token_type);
    }

    function mintBatch_721(
        address nft721,
        address to,
        string[] memory tokenURIs,
        uint256[] calldata token_types
    ) external onlyRole(MINT_ROLE) {
        NFT721 token = NFT721(nft721);
        token.mintBatch(to, tokenURIs, token_types);
    }
}
