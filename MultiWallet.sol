// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.21;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";

/**
 * @title MultiWallet
 * @dev Un contrato multisig que permite a múltiples firmantes aprobar y ejecutar transacciones.
 */
contract MultiWallet is ReentrancyGuard, AccessControl {
    // Identificador del rol de firmante
    bytes32 public constant SIGNER_ROLE = keccak256("SIGNER_ROLE");

    // Máximo número de firmantes
    uint256 public MAX_SIGNERS;

    // Enumeración que representa tipos de transacciones
    enum TransactionType {
        ETH, // Transferencia de Ether
        ERC20 // Transferencia de un token ERC20
    }

    // Estructura que representa una transacción
    struct Transaction {
        TransactionType txType; // Tipo de transacción
        address token; // Dirección del token (solo para ERC20)
        address payable destination; // Destino de la transacción
        uint256 value; // Monto a enviar
        uint256 approvals; // Número de aprobaciones
        bool executed; // Indica si la transacción ha sido ejecutada
    }

    // Lista de transacciones
    Transaction[] public transactions;

    // Lista de firmantes
    address[] public signers;

    // Mapeo para rastrear las aprobaciones de transacciones por firmante
    mapping(uint256 => mapping(address => bool)) public transactionApprovals;

    /**
     * @dev Constructor del contrato MultiWallet.
     * @param maxSigners Número máximo de firmantes permitidos.
     */
    constructor(uint256 maxSigners) {
        grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        grantRole(SIGNER_ROLE, msg.sender);
        signers.push(msg.sender);

        MAX_SIGNERS = maxSigners;
    }

    // Modificador que permite la ejecución solo al propietario del contrato
    modifier onlyOwner() {
        require(hasRole(DEFAULT_ADMIN_ROLE, msg.sender), "No eres el duenno");
        _;
    }

    // Modificador que permite la ejecución solo a firmantes
    modifier onlySigner() {
        require(
            hasRole(SIGNER_ROLE, msg.sender),
            "No tienes el rol de firmante"
        );
        _;
    }

    /**
     * @dev Permite al propietario agregar un nuevo firmante.
     * @param _signer Dirección del nuevo firmante.
     */
    function addSigner(address _signer) external onlyOwner {
        require(
            signers.length < MAX_SIGNERS,
            "Se ha alcanzado el maximo de firmantes"
        );
        require(
            !hasRole(SIGNER_ROLE, _signer),
            "La direccion ya es un firmante"
        );

        grantRole(SIGNER_ROLE, _signer);
        signers.push(_signer);
    }

    /**
     * @dev Permite al propietario eliminar un firmante.
     * @param _signer Dirección del firmante a eliminar.
     */
    function removeSigner(address _signer) external onlyOwner {
        require(
            hasRole(SIGNER_ROLE, _signer),
            "La direccion no es un firmante"
        );

        // Revocar el rol de firmante
        revokeRole(SIGNER_ROLE, _signer);

        // Eliminar el firmante del array 'signers'
        for (uint256 i = 0; i < signers.length; i++) {
            if (signers[i] == _signer) {
                signers[i] = signers[signers.length - 1];
                signers.pop();
                break;
            }
        }

        // Eliminar cualquier aprobación pendiente del firmante
        for (uint256 j = 0; j < transactions.length; j++) {
            if (transactionApprovals[j][_signer]) {
                transactions[j].approvals--;
                transactionApprovals[j][_signer] = false;
            }
        }
    }

    /**
     * @dev Permite a un firmante agregar una transacción pendiente.
     * @param _type Tipo de transacción (ETH o ERC20).
     * @param _token Dirección del token (solo para ERC20).
     * @param _destination Dirección de destino de la transacción.
     * @param _value Monto a enviar.
     */
    function addTransaction(
        TransactionType _type,
        address _token,
        address payable _destination,
        uint256 _value
    ) external onlySigner {
        Transaction memory newTx = Transaction({
            txType: _type,
            token: _token,
            destination: _destination,
            value: _value,
            approvals: 0,
            executed: false
        });
        transactions.push(newTx);
    }

    /**
     * @dev Permite a un firmante aprobar una transacción pendiente.
     * @param _transactionIndex Índice de la transacción en la lista.
     */
    function approveTransaction(uint256 _transactionIndex) external onlySigner {
        require(
            _transactionIndex < transactions.length,
            "Transaccion no valida"
        );
        Transaction storage txn = transactions[_transactionIndex];

        require(!txn.executed, "La transaccion ya ha sido ejecutada");
        require(
            !transactionApprovals[_transactionIndex][msg.sender],
            "Ya aprobaste esta transaccion"
        );

        transactionApprovals[_transactionIndex][msg.sender] = true;
        txn.approvals++;
    }

    /**
     * @dev Permite a un firmante ejecutar una transacción que ha sido aprobada.
     * @param _transactionIndex Índice de la transacción en la lista.
     */
    function executeTransaction(uint256 _transactionIndex) external onlySigner {
        require(
            _transactionIndex < transactions.length,
            "Transaccion no valida"
        );
        Transaction storage txn = transactions[_transactionIndex];

        require(txn.approvals >= 2, "Se requieren al menos 2 aprobaciones");
        require(!txn.executed, "La transaccion ya ha sido ejecutada");

        if (txn.txType == TransactionType.ETH) {
            require(
                address(this).balance >= txn.value,
                "No hay suficiente ETH en el contrato"
            );
            txn.destination.transfer(txn.value);
        } else {
            IERC20 token = IERC20(txn.token);
            uint256 balance = token.balanceOf(address(this));
            require(
                balance >= txn.value,
                "No hay suficientes tokens en el contrato"
            );
            token.transfer(txn.destination, txn.value);
        }

        txn.executed = true;
    }
}
