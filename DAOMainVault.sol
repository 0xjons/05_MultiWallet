// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts@4.0.0/access/Ownable.sol";
import "./DAOManagement.sol";

contract DAOMainVault is Ownable {
    DAOManagement public daoManagement;

    event TransferERC20(address indexed token, uint256 amount);
    event TransferERC721(address indexed token, uint256 tokenId);
    event TransferETH(uint256 amount);
    event EmergencyWithdrawal(address token, uint256 amount);

    constructor(address _daoManagement) {
        require(_daoManagement != address(0), "DAOManagement address cannot be zero.");
        daoManagement = DAOManagement(_daoManagement);
    }

    // Función para transferir tokens ERC20 al mismo contrato
    function transferERC20(IERC20 token, uint256 amount) public {
        require(daoManagement.isAuthorized(msg.sender), "Sender is not authorized.");
        token.transfer(address(this), amount);
        emit TransferERC20(address(token), amount);
    }

    // Función para transferir tokens ERC721 al mismo contrato
    function transferERC721(IERC721 token, uint256 tokenId) public {
        require(daoManagement.isAuthorized(msg.sender), "Sender is not authorized.");
        token.safeTransferFrom(msg.sender, address(this), tokenId);
        emit TransferERC721(address(token), tokenId);
    }

    // Función para transferir ETH al mismo contrato
    function transferETH(uint256 amount) public {
        require(daoManagement.isAuthorized(msg.sender), "Sender is not authorized.");
        require(address(this).balance >= amount, "Insufficient balance");
        payable(address(this)).transfer(amount);
        emit TransferETH(amount);
    }

    // Función de retiro de emergencia
    function emergencyWithdraw(address _token, uint256 _amount) external onlyOwner {
        if (_token == address(0)) {
            payable(owner()).transfer(_amount);
        } else {
            IERC20(_token).transfer(owner(), _amount);
        }
        emit EmergencyWithdrawal(_token, _amount);
    }

    // Fallback para recibir ETH
    receive() external payable {}

    // Modificada para crear una transacción multisig en lugar de transferir directamente
    function withdraw(address payable _to, uint256 _amount) public onlyOwner {
        require(_amount <= address(this).balance, "Insufficient balance");
        // En lugar de transferir, creamos una transacción multisig para el retiro
        daoManagement.submitTransaction(TransactionType.ETH, address(0), _to, _amount);
    }
}
