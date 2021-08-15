//SPDX-License-Identifier:UNIDENTIFIED

pragma solidity ^0.8.0;
/**
Create a token based on ERC20 which is buyable. Following features should present;

1. Anyone can get the token by paying against ether
2. Add fallback payable method to Issue token based on Ether received. Say 1 Ether = 100 tokens.
3. There should be an additional method to adjust the price that allows the owner to adjust the price.
*/
abstract contract BaseERC20{
    function _msgSender() internal view virtual returns(address){
        return msg.sender;
    }
    function _msgData() internal view virtual returns(bytes calldata){
        return msg.data;
    }
    function _msgValue() internal view virtual returns(uint256){
        return msg.value;
    }
}

interface MethodsERC20{
    function totalSupply() external view returns(uint256);
    function balanceOf(address recipient) external view returns(uint256);
    function transfer(address recipient, uint256 amount) external returns(bool);
    function approve(address spender, uint256 amount) external returns(bool);
    function allowance(address owner, address spender) external returns(uint256);
    function transferFrom(address sender, address recipient, uint256 amount) external returns(bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
    function buy() external payable returns(bool);
    fallback() external payable;
    event RateChange(address indexed from, string, uint256);
}

interface MetaDataERC20 is MethodsERC20{
    function name() external view returns(string memory);
    function symbol() external view returns(string memory);
    function decimal() external view returns(uint8);
}

contract MyERC20 is BaseERC20, MethodsERC20, MetaDataERC20{
    
    address public tokenOwner;
    mapping(address=>uint256) private _balances;
    mapping(address => mapping(address=>uint256)) private _allowance;
    uint256 private _totalSupply;
    string private _name;
    string private _symbol;
    uint8 private _decimals;
    uint256 public tokenPrice;
    
    constructor(string memory name_, string memory symbol_, uint8 decimals_, uint256 totalSupply_){
        tokenOwner = _msgSender();
        tokenPrice = .01 ether;
        _name = name_;
        _symbol = symbol_;
        _decimals = decimals_;
        _balances[tokenOwner] = totalSupply_ *10**decimals_;
        _totalSupply = _balances[tokenOwner];
    }
    
    modifier onlyOwner(){
        require(_msgSender() == tokenOwner,"Only Owner can call this function");
        _;
    }
    
    fallback() external virtual override payable{
         uint256 contractBalance = address(this).balance; 
         contractBalance += _msgValue();
    }
    function changeTokenPrice(uint256 _tokenConversion) external onlyOwner() returns(uint256){
        return tokenPrice = (1 ether) / _tokenConversion;
        emit RateChange(_msgSender(), " has change the token price to ", tokenPrice);
    }
    function buy() external payable virtual override returns(bool){
        require (_msgSender() != tokenOwner,"Token Owner cannot buy the tokens.");
        require (_msgValue() > 0 ether,"Ethers are required to buy tokens");
        uint256 amountOfTokens;
        amountOfTokens = (_msgValue()/tokenPrice) *10**_decimals;
        _tranfer(tokenOwner,_msgSender(),amountOfTokens);
        return true;
    }
    function contractEtherBalance() view external onlyOwner() returns(uint256){
        return address(this).balance;
    }
    function destroyToken() external payable onlyOwner(){
        selfdestruct(payable(tokenOwner));
    }
    
    function name() external virtual override view returns(string memory){
        return _name;
    }
    function symbol() external virtual override view returns(string memory){
        return _symbol;
    }
    function decimal() external virtual override view returns(uint8){
        return _decimals;
    }
    
    function totalSupply() external virtual override view returns(uint256){
        return _totalSupply;
    }
    function balanceOf(address recipient) external virtual override view returns(uint256){
        return _balances[recipient];
    }
    
    function _tranfer(address sender, address recipient, uint256 amount) internal virtual{
        require(sender != address(0),"Invalid Sender");
        require(recipient != address(0),"Invalid Recipient");
        _beforeTokensTransfer(sender, recipient, amount);
        
        uint256 senderBalance = _balances[sender];
        require (senderBalance >= amount,"The account does not have sufficient to execute token transfer.");
        unchecked{
            _balances[sender] = senderBalance - amount;
        }
        _balances[recipient] += amount;
        emit Transfer(sender, recipient, amount);
        _afterTokensTransfer(sender, recipient, amount);
    }
    function _beforeTokensTransfer(address from, address to, uint256 amount) internal virtual{
        
    }
    function _afterTokensTransfer(address from, address to, uint256 amount) internal virtual{
        
    }
    function transfer(address recipient, uint256 amount) external virtual override returns(bool){
        _tranfer(_msgSender(),recipient,amount);
        return true;
    }
    
    function _approve(address owner, address spender, uint256 amount) internal virtual{
        require(owner != address(0),"Invalid Owner");
        require(spender != address(0),"Invalid Spender");
        _allowance[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }
    function allowance(address owner, address spender) external virtual override returns(uint256){
        return _allowance[owner][spender];
    }
    function approve(address spender, uint256 amount) external virtual override returns(bool){
        _approve(_msgSender(), spender, amount);
        return true;
    }
    function transferFrom(address sender, address recipient, uint256 amount) external virtual override returns(bool){
        _tranfer(sender, recipient, amount);
        uint256 currentAllowance = _allowance[sender][_msgSender()];
        require(currentAllowance >= amount, "Transfer amount exceeds available Allowance!");
        unchecked{
            _approve(sender, _msgSender(), currentAllowance - amount);
        }
        return true;
    }
    
}