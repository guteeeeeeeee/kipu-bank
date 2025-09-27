// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.20;

/**
 * @title Kipu Bank
 * @author Jose Maria
 * @notice contrato que permite al usuario depositar y retirar ether
 */

contract Kipu_Bank{

    /// @notice mapea cada usuario con su balance
    mapping (address usuario => uint256 monto) private s_usuarios_balance;
    /// @notice cantidad de depositos totales
    uint256 public s_cant_depositos;
    /// @notice cantidad de retiros totales
    uint256 public s_cant_retiros; //revisar los modificadores de acceso
    /// @notice umbral de retiro por transaccion
    uint256 public immutable s_umbral;
    /// @notice limite global de depositos
    uint256 private constant s_limite_global_depositos = 1000;
    /// @notice monto minimo de ether para depositar
    uint256 private constant MONTO_MINIMO_DEPOSITO = 0.000001 ether;
    /// @notice monto minimo de ether para retirar
    uint256 private constant MONTO_MINIMO_RETIRO = 0.000001 ether;

    /// @notice avisa el monto depositado por usuario de manera exitosa
    event DepositoExitoso(address indexed usuario, uint256 monto_depositado);
    /// @notice avisa el monto retirado por usuario de manera exitosa
    event RetiroExitoso(address indexed usuario, uint256 monto_retirado);

    /// @notice se intenta retirar una cantidad mayor al umbral
    error RetiroMayorQueUmbral(uint256 monto_requerido, uint256 umbral);
    /// @notice intenta retirar monto mayor a su balance
    error FondosInsuficientes(uint256 monto_requerido, uint256 balance_actual);
    /// @notice se supero la cantidad global de depositos
    error SuperoLimiteDepositos(uint256 limite);
    /// @notice se intenta depositar un monto menor al minimo
    error MenorAlMinimoDeposito(uint256 monto_enviado,uint256 monto_minimo);
    /// @notice se intenta retirar un monto menor al minimo
    error MenorAlMinimoRetiro(uint256 monto_pedido,uint256 monto_minimo);
    /// @notice el usuario no tiene fondos
    error UsuarioSinFondos(address usuario);

    modifier menor_limite_depositos(){
        if(s_cant_depositos >= s_limite_global_depositos){ //si se llego al limite de depositos
            revert SuperoLimiteDepositos(s_limite_global_depositos);
        }
        _;
    }

    modifier usuario_tiene_fondos(){
        if(s_usuarios_balance[msg.sender]==0){
            revert UsuarioSinFondos(msg.sender);
        }
        _;
    }

    constructor(){
        s_umbral = 1 ether;
    }
     
    ///@notice recibe eth sin datos
    ///@dev llama internamente a _deposit() para conservar msg.sender y msg.value
    receive() external payable {
        _deposit();
    }
   
    ///@notice maneja llamadas con datos no vacios o funciones inexistentes
    ///@dev si manda eth lo trato como deposito, si no revert
    fallback() external payable {
        if (msg.value > 0) {
            _deposit();
        } else {
            revert("Funcion inexistente");
        }
    }

    /// @notice permite depositar en el balance del usuario
    function depositar() external payable {
        _deposit(); 
    }

    /*
    /// @notice permite retirar un monto del balance del usuario
    /// @param monto que se desea retirar
    */
    function retirar(uint256 monto_a_retirar) external usuario_tiene_fondos {
        uint256 balance_usuario = balance_del_usuario(msg.sender); //balance del usuario
        if(monto_a_retirar > s_umbral){ //si el monto es mayor al umbral
            revert RetiroMayorQueUmbral(monto_a_retirar, s_umbral);
        }
        if(monto_a_retirar < MONTO_MINIMO_RETIRO){ //si el monto es menor al minimo
            revert MenorAlMinimoRetiro(monto_a_retirar,MONTO_MINIMO_RETIRO);
        }
        if (balance_usuario < monto_a_retirar){ //si el monto es mayor que el balance
            revert FondosInsuficientes(monto_a_retirar, balance_usuario);
        }

        s_usuarios_balance[msg.sender] -= monto_a_retirar; //retiro el monto del balance del usuario
        (bool success, ) = msg.sender.call{value: monto_a_retirar}(""); //le transfiero
        require(success, "fallo la transferencia al usuario");
        s_cant_retiros += 1;

        emit RetiroExitoso(msg.sender, monto_a_retirar);
    }

    /// @notice cantidad de depositos globales
    /// @return cantidad de depositos realizados en el contrato
    function cantidad_depositos() external view returns (uint256 cantidad){
        return s_cant_depositos;
    }

    /// @notice cantidad de retiros globales
    /// @return cantidad de retiros realizados en el contrato
    function cantidad_retiros() external view returns (uint256 cantidad){
        return s_cant_retiros;
    }

    /// @notice permite depositar en el balance del usuario
    /// @dev funcion creada para tambien llamar desde receive() y fallback()
    function _deposit() internal menor_limite_depositos{
        if(msg.value < MONTO_MINIMO_DEPOSITO){ //si el monto es menor al minimo
            revert MenorAlMinimoDeposito(msg.value,MONTO_MINIMO_DEPOSITO);
        }
        
        s_usuarios_balance[msg.sender] += msg.value; //actualizo balance
        s_cant_depositos += 1;

        emit DepositoExitoso(msg.sender, msg.value);
    }

    /// @notice balance del usuario
    /// @param usuario del que se desea averiguar balance
    /// @return balance del usuario
    function balance_del_usuario(address usuario) private view returns(uint256 balance){
        return s_usuarios_balance[usuario];
    }

}
