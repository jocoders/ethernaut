// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract UniCollectionNFT is ERC721, Ownable {
    // Each collection gets a reserved block of token IDs.
    uint256 public constant TOKEN_OFFSET = 1e6; // e.g., up to 1,000,000 tokens per collection
    uint256 public collectionCount;

    struct Collection {
        string name;
        string baseURI;
        uint256 nextLocalTokenId; // Local token ID counter (starts at 1)
    }

    // Mapping from collection ID to its details
    mapping(uint256 => Collection) public collections;

    // Events for collection creation and minting
    event CollectionCreated(uint256 indexed collectionId, string name, string baseURI);
    event TokenMinted(uint256 indexed collectionId, uint256 tokenId, address to);

    constructor(string memory name, string memory symbol) ERC721(name, symbol) Ownable(msg.sender) {}

    /**
     * @dev Creates a new collection with a given name and base URI.
     * Only the contract owner can create collections.
     * @return The new collection's ID.
     */
    function createCollection(string memory collectionName, string memory baseURI)
        external
        onlyOwner
        returns (uint256)
    {
        collectionCount++;
        uint256 newCollectionId = collectionCount;
        collections[newCollectionId] = Collection({name: collectionName, baseURI: baseURI, nextLocalTokenId: 1});
        emit CollectionCreated(newCollectionId, collectionName, baseURI);
        return newCollectionId;
    }

    /**
     * @dev Mints a new token within a specified collection to address `to`.
     * Only the contract owner can mint tokens.
     * @return The newly minted global token ID.
     */
    function mint(uint256 collectionId, address to) external onlyOwner returns (uint256) {
        require(collectionId > 0 && collectionId <= collectionCount, "Collection does not exist");
        Collection storage col = collections[collectionId];
        uint256 localId = col.nextLocalTokenId;
        uint256 globalTokenId = collectionId * TOKEN_OFFSET + localId;

        // Increment the next token ID before minting to prevent reentrancy
        col.nextLocalTokenId++;

        _mint(to, globalTokenId);
        emit TokenMinted(collectionId, globalTokenId, to);
        return globalTokenId;
    }
}
