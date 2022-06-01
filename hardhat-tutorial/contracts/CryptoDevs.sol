// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./IWhitelist.sol";

contract CryptoDevs is ERC721Enumerable, Ownable {
    
    // Base URI + Token ID
    string _baseTokenURI;

    // price for each NFT
    uint256 public _price = 0.01 ether;

    // use to pause the contract in case of emergency 
    bool public _paused;

    // max num of NFT
    uint256 public maxTokenIds = 20;

    // total minted NFT
    uint256 public totalTokenIds;

    IWhitelist whitelist;

    // use to check if presale started
    bool public presaleStarted;

    // timestamp when presale will end
    uint256 public presaleEndedTimestamp;

    modifier onlyWhenNotPaused {
        require(!_paused, "Contract currently paused");
        _;
    }

    constructor (string memory baseURI, address whitelistContract) ERC721("Crypto Devs", "CD") {
        _baseTokenURI = baseURI;
        whitelist = IWhitelist(whitelistContract);
    }

    // only owner can start presale
    function startPresale() public onlyOwner {
        presaleStarted = true;

        presaleEndedTimestamp = block.timestamp + 5 minutes;
    }

    // allow user to mint during presale only when it's not paused
    function presaleMint() public payable onlyWhenNotPaused {
        require(presaleStarted && block.timestamp < presaleEndedTimestamp, "Presale is not running");
        require(whitelist.whitelistedAddresses(msg.sender), "You are not whitelisted");
        require(totalTokenIds < maxTokenIds, "Exceeded maximum Crypto Devs supply");
        require(msg.value >= _price, "Ether sent is not correct");

        totalTokenIds += 1;

        _safeMint(msg.sender, totalTokenIds);
    }

    // mint when it's not paused and presale has ended
    function mint() public payable onlyWhenNotPaused {
        require(presaleStarted && block.timestamp >=  presaleEndedTimestamp, "Presale has not ended yet");
        require(totalTokenIds < maxTokenIds, "Exceed maximum Crypto Devs supply");
        require(msg.value >= _price, "Ether sent is not correct");
        totalTokenIds += 1;
        _safeMint(msg.sender, totalTokenIds); 
    }

    // get base URI
    function _baseURI() internal view virtual override returns (string memory) {
        return _baseTokenURI;
    }

    function setPaused(bool val) public onlyOwner {
        _paused = val;
    }

    function withdraw() public onlyOwner {
        address _owner = owner();
        uint256 amount = address(this).balance;
        (bool sent, ) = _owner.call{value: amount}("");
        require(sent, "Failed to send Ether");
    }

    receive() external payable {}

    fallback() external payable {}

}