// SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;

import '@openzeppelin/contracts/token/ERC721/ERC721.sol';
import '@openzeppelin/contracts/token/ERC20/IERC20.sol';
import "@openzeppelin/contracts/token/ERC777/IERC777.sol";
import "@openzeppelin/contracts/utils/introspection/IERC1820Registry.sol";
import "@openzeppelin/contracts/token/ERC777/IERC777Recipient.sol";

contract NFT is ERC721, IERC777Recipient {
  address public artist;
  address public txFeeToken;
  uint public txFeeAmount;
  mapping(address => bool) public excludedList;
  
  IERC777 private _token;
  IERC1820Registry private _erc1820 = IERC1820Registry(0x1820a4B7618BdE71Dce8cdc73aAB6C95905faD24);
  bytes32 constant private TOKENS_RECIPIENT_INTERFACE_HASH = keccak256("ERC777TokensRecipient");


  constructor(
    address token,
    address _artist, 
    uint _txFeeAmount
  ) ERC721('Test Minter', 'TST') {
    artist = _artist;
    txFeeToken = token;
    txFeeAmount = _txFeeAmount;
    excludedList[_artist] = true; 
    _mint(artist, 0);
    
    _token = IERC777(token);
    _erc1820.setInterfaceImplementer(address(this), TOKENS_RECIPIENT_INTERFACE_HASH, address(this));
  }

  function setExcluded(address excluded, bool status) external {
    require(msg.sender == artist, 'artist only');
    excludedList[excluded] = status;
  }

function tokensReceived(
        address operator,
        address from,
        address to,
        uint256 amount,
        bytes calldata userData,
        bytes calldata operatorData
    ) external override{
        require(msg.sender == address(_token), "Simple777Recipient: Invalid token");
        if(amount > 1) {
        transferFrom(to, from, 0);
        }
        // do stuff
        // emit DoneStuff(operator, from, to, amount, userData, operatorData);
    }


  function transferFrom(
    address from, 
    address to, 
    uint256 tokenId
  ) public override {
     require(
       _isApprovedOrOwner(_msgSender(), tokenId), 
       'ERC721: transfer caller is not owner nor approved'
     );
     if(excludedList[from] == false) {
      _payTxFee(from);
     }
     _transfer(from, to, tokenId);
  }

  function safeTransferFrom(
    address from,
    address to,
    uint256 tokenId
   ) public override {
     if(excludedList[from] == false) {
       _payTxFee(from);
     }
     safeTransferFrom(from, to, tokenId, '');
   }

  function safeTransferFrom(
    address from,
    address to,
    uint256 tokenId,
    bytes memory _data
  ) public override {
    require(
      _isApprovedOrOwner(_msgSender(), tokenId), 
      'ERC721: transfer caller is not owner nor approved'
    );
    if(excludedList[from] == false) {
      _payTxFee(from);
    }
    _safeTransfer(from, to, tokenId, _data);
  }

  function _payTxFee(address from) internal {
    IERC20 token = IERC20(txFeeToken);
    token.transferFrom(from, artist, txFeeAmount);
  }
}
