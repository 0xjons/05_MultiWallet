// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

// Enumeración que representa tipos de transacciones
enum TransactionType {
    ETH, // Transferencia de Ether
    ERC20 // Transferencia de un token ERC20
}

interface IMultiSigWallet {
    function submitTransaction(
        TransactionType _type,
        address _token,
        address payable _destination,
        uint256 _value
    ) external returns (uint256 transactionId);

    function confirmTransaction(uint256 transactionId) external;

    function executeTransaction(uint256 transactionId) external;

    function isConfirmed(uint256 transactionId) external view returns (bool);
}

contract DAOManagement is IMultiSigWallet {
    address goon;
    // Un único conjunto de propietarios que son también las wallets autorizadas
    address[] public authWallets;
    mapping(address => bool) public isAuthorized;
    uint256 public required; // núm de firmas necesarias para poder ejecutar una tx
    uint256 public walletCount; // contador de las wallets autorizadas
    uint256 public constant MAX_WALLETS = 5; // núm máximo de wallets autorizadas

    // Estructura que representa una transacción
    struct Transaction {
        TransactionType txType; // Tipo de transacción
        address token; // Dirección del token (solo para ERC20)
        address payable destination; // Destino de la transacción
        uint256 value; // Monto a enviar
        uint256 approvals; // Número de aprobaciones
        bool executed; // Indica si la transacción ha sido ejecutada
    }

    Transaction[] public transactions;
    mapping(uint256 => mapping(address => bool)) public confirmations;

    event OwnerAdded(address indexed owner);
    event OwnerRemoved(address indexed owner);
    event TransactionSubmitted(uint256 indexed transactionId);
    event TransactionConfirmed(
        address indexed sender,
        uint256 indexed transactionId
    );
    event TransactionExecuted(uint256 indexed transactionId);


    modifier onlyOwner() {
        require(goon == msg.sender, "Not owner");
        _;
    }

    modifier onlyAuthorized() {
        require(isAuthorized[msg.sender], "Not authorized");
        _;
    }

    constructor(address[] memory _owners, uint256 _required) {
        require(_owners.length > 0, "Owners required");
        require(
            _required > 0 && _required <= _owners.length,
            "Invalid required number of owners"
        );

        for (uint256 i = 0; i < _owners.length; i++) {
            address owner = _owners[i];
            require(owner != address(0), "Invalid owner");
            require(!isAuthorized[owner], "Owner not unique");

            isAuthorized[owner] = true;
            authWallets.push(owner);
        }
        required = _required;
    }

    // Funciones para añadir o eliminar propietarios
    function addOwner(address _owner) public onlyOwner {
        require(_owner != address(0), "Invalid owner");
        require(!isAuthorized[_owner], "Owner already exists");

        isAuthorized[_owner] = true;
        authWallets.push(_owner);

        emit OwnerAdded(_owner);
    }

    function removeOwner(address _owner) public onlyOwner {
        require(isAuthorized[_owner], "Not an owner");

        isAuthorized[_owner] = false;
        for (uint256 i = 0; i < authWallets.length; i++) {
            if (authWallets[i] == _owner) {
                authWallets[i] = authWallets[authWallets.length - 1];
                authWallets.pop();
                break;
            }
        }

        emit OwnerRemoved(_owner);
    }

    // Funciones para manejar transacciones MultiSig dee una manera más genérica, permitiendo
    // enviar "data"
    function submitTransaction(
        TransactionType _type,
        address _token,
        address payable _destination,
        uint256 _value
    ) public onlyAuthorized returns (uint256 transactionId) {
        transactionId = transactions.length;
        transactions.push(
            Transaction({
                txType: _type,
                token: _token,
                destination: _destination,
                value: _value,
                approvals: 0,
                executed: false
            })
        );
        emit TransactionSubmitted(transactionId);
        return transactionId;
    }

    function confirmTransaction(uint256 transactionId) public onlyAuthorized {
        require(
            transactionId < transactions.length,
            "Transaction does not exist"
        );
        require(
            !confirmations[transactionId][msg.sender],
            "Transaction already confirmed"
        );

        confirmations[transactionId][msg.sender] = true;
        emit TransactionConfirmed(msg.sender, transactionId);
    }

    function executeTransaction(uint256 transactionId) public onlyAuthorized {
        require(
            transactions[transactionId].executed == false,
            "Transaction already executed"
        );
        require(isConfirmed(transactionId), "Transaction not confirmed");

        Transaction storage txn = transactions[transactionId];
        txn.executed = true;
        // Ejecutar la transacción sin pasar datos adicionales
        (bool success, ) = txn.destination.call{value: txn.value}("");
        require(success, "Transaction failed");
        emit TransactionExecuted(transactionId);
    }

    function isConfirmed(uint256 transactionId) public view returns (bool) {
        uint256 count = 0;
        for (uint256 i = 0; i < authWallets.length; i++) {
            if (confirmations[transactionId][authWallets[i]]) count += 1;
            if (count == required) return true;
        }
        return false;
    }

}
