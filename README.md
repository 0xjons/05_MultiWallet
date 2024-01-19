# DAO Management System

Este sistema de gestión DAO se compone de dos contratos principales: `DAOManagement` y `DAOMainVault`, implementados en Solidity.

## DAOManagement

El contrato `DAOManagement` es un sistema de billetera multifirma que permite a un conjunto de propietarios autorizados gestionar transacciones de forma colectiva. Este contrato es responsable de las siguientes funcionalidades clave:

- **Manejo de Propietarios**: Permite añadir o eliminar propietarios del sistema.
- **Envío de Transacciones**: Permite enviar transacciones de diferentes tipos (ETH o ERC20).
- **Confirmación y Ejecución de Transacciones**: Las transacciones requieren confirmaciones de los propietarios autorizados antes de su ejecución.
- **Verificación de Confirmaciones**: Proporciona la capacidad de verificar si una transacción ha sido suficientemente confirmada.

### Características Principales

- **Manejo Flexible de Transacciones**: Soporta transacciones de ETH y tokens ERC20.
- **Seguridad Multifirma**: Requiere múltiples confirmaciones para ejecutar transacciones.
- **Gestión de Propietarios**: Funcionalidad para gestionar dinámicamente los propietarios autorizados.

## DAOMainVault

El contrato `DAOMainVault` actúa como un depósito seguro para los activos de la DAO y está diseñado para interactuar con el contrato `DAOManagement`. Sus funciones principales incluyen:

- **Transferencia de Activos**: Permite transferir tokens ERC20 y ERC721 al contrato.
- **Retiros de Emergencia**: Funcionalidad para que el propietario retire activos en situaciones de emergencia.
- **Retiros Seguros**: Implementa un mecanismo para retirar ETH de forma segura a través de transacciones multifirma.

### Interacción con DAOManagement

- **Autorización y Control**: Las acciones críticas requieren autorización a través del sistema multifirma de `DAOManagement`.
- **Transacciones Protegidas**: Las transferencias y retiros están protegidos por el sistema de confirmación multifirma.

## Implementación y Uso

Este sistema está diseñado para ser utilizado por organizaciones descentralizadas que requieren un nivel alto de seguridad y gobernanza colectiva en la gestión de sus activos digitales.

### Notas de Implementación

- **Solidity Version**: Se utiliza Solidity versión 0.8.23.
- **OpenZeppelin Contracts**: Se aprovechan los contratos de OpenZeppelin para tokens ERC20 y ERC721, así como para el patrón `Ownable`.

---

*Este README proporciona una visión general de los contratos `DAOManagement` y `DAOMainVault`, destacando sus características y funcionalidades clave para la gestión de activos en una DAO.*
