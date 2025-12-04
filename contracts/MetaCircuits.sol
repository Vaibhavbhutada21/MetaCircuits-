// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

/**
 * @title MetaCircuits
 * @notice Modular NFT where users can attach upgrade components to boost attributes
 */

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract MetaCircuits is ERC721Enumerable, Ownable {
    using Strings for uint256;

    struct CircuitStats {
        uint256 power;
        uint256 speed;
        uint256 efficiency;
    }

    // Base NFT → total stats
    mapping(uint256 => CircuitStats) public nftStats;

    // BaseURI for token metadata
    string public baseURI;

    // Component marketplace (componentId → component attributes)
    struct Component {
        uint256 power;
        uint256 speed;
        uint256 efficiency;
        uint256 price;
        bool active;
    }

    mapping(uint256 => Component) public components;
    uint256 public componentCount;

    constructor(string memory _baseURI) ERC721("MetaCircuits", "MCRKT") {
        baseURI = _baseURI;
    }

    // -------- Mint NFT --------
    function mint() external {
        uint256 newId = totalSupply() + 1;
        _safeMint(msg.sender, newId);
        nftStats[newId] = CircuitStats(1, 1, 1); // base attributes
    }

    // -------- Owner Creates / Updates Components --------
    function addComponent(uint256 p, uint256 s, uint256 e, uint256 price) external onlyOwner {
        components[++componentCount] = Component(p, s, e, price, true);
    }

    function updateComponent(
        uint256 componentId, 
        uint256 p, 
        uint256 s, 
        uint256 e, 
        uint256 price, 
        bool active
    ) external onlyOwner {
        require(componentId <= componentCount, "Invalid component");
        components[componentId] = Component(p, s, e, price, active);
    }

    // -------- User Buys Component and Applies to NFT --------
    function attachComponent(uint256 tokenId, uint256 componentId) external payable {
        require(ownerOf(tokenId) == msg.sender, "Not NFT owner");
        require(componentId <= componentCount, "Invalid component");
        Component memory comp = components[componentId];
        require(comp.active, "Inactive component");
        require(msg.value >= comp.price, "Insufficient ETH");

        nftStats[tokenId].power += comp.power;
        nftStats[tokenId].speed += comp.speed;
        nftStats[tokenId].efficiency += comp.efficiency;
    }

    // -------- Get NFT Stats (for Gameplay / Leaderboards / etc.) --------
    function getStats(uint256 tokenId) external view returns (uint256 power, uint256 speed, uint256 efficiency) {
        CircuitStats memory s = nftStats[tokenId];
        return (s.power, s.speed, s.efficiency);
    }

    // -------- Withdraw Funds --------
    function withdraw() external onlyOwner {
        payable(owner()).transfer(address(this).balance);
    }

    // -------- Metadata --------
    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        require(_exists(tokenId), "NFT does not exist");
        return string(abi.encodePacked(baseURI, "/", tokenId.toString(), ".json"));
    }

    function setBaseURI(string memory newBaseURI) external onlyOwner {
        baseURI = newBaseURI;
    }
}
