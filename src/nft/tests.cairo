// Import the interface and dispatcher to be able to interact with the contract.
use super::interface::{
    INFTDispatcher, INFTDispatcherTrait
};
use super::contract::NFT;
use openzeppelin::access::ownable::interface::{IOwnableDispatcher, IOwnableDispatcherTrait};
use openzeppelin::upgrades::interface::{IUpgradeableDispatcher, IUpgradeableDispatcherTrait};

// Import the deploy syscall to be able to deploy the contract.
use starknet::class_hash::Felt252TryIntoClassHash;
use starknet::{
    deploy_syscall, ContractAddress, get_contract_address,
    contract_address_const, class_hash_const
};

// Use starknet test utils to fake the transaction context.
use starknet::testing::{set_caller_address, set_contract_address};

// Deploy the contract and return its dispatcher.
fn deploy(
    owner: ContractAddress, name: felt252, symbol: felt252, max_supply: u256
) -> (INFTDispatcher, IOwnableDispatcher, IUpgradeableDispatcher) {
    // Set up constructor arguments.
    let mut calldata = ArrayTrait::new();
    owner.serialize(ref calldata);
    name.serialize(ref calldata);
    symbol.serialize(ref calldata);
    max_supply.serialize(ref calldata);

    // Declare and deploy
    let (contract_address, _) = deploy_syscall(
        NFT::TEST_CLASS_HASH.try_into().unwrap(), 0, calldata.span(), false
    )
        .unwrap();

    // Return dispatchers.
    // The dispatcher allows to interact with the contract based on its interface.
    (
        INFTDispatcher { contract_address },
        IOwnableDispatcher { contract_address },
        IUpgradeableDispatcher { contract_address }
    )
}

#[test]
#[available_gas(2000000000)]
fn test_deploy() {
    let owner = contract_address_const::<1>();
    let name = 'Cool Token';
    let symbol = 'COOL';
    let max_supply = 100000;
    let (contract, ownable, _) = deploy(owner, name, symbol, max_supply);

    assert(contract.name() == name, 'wrong name');
    assert(contract.symbol() == symbol, 'wrong symbol');
    assert(contract.max_supply() == max_supply, 'wrong max supply');

    assert(ownable.owner() == owner, 'wrong admin');
}

#[test]
#[available_gas(2000000000)]
fn test_mint() {
    let owner = contract_address_const::<123>();
    set_contract_address(owner);
    let (contract, _, _) = deploy(owner, 'Token', 'T', 300);

    // set the base URI
    let base_uri = array![
        'ipfs://lllllllllllllooooooooooo',
        'nnnnnnnnnnngggggggggggggggggggg',
        'aaaaddddddrrrrrreeeeeeesssss'
    ];
    contract.set_base_uri(base_uri.clone());

    let recipient = contract_address_const::<1>();
    contract.mint(recipient, 100);
    contract.mint(recipient, 50);

    assert(contract.total_supply() == 150, 'wrong total supply');
    assert(contract.balance_of(recipient) == 150, 'wrong balance after mint');
    assert(contract.owner_of(150) == recipient, 'wrong owner');
    let token_uri_array = contract.token_uri(150);
    assert(
        *token_uri_array.at(0) == *base_uri.at(0), 'wrong token uri (part 1)'
    );
    assert(
        *token_uri_array.at(1) == *base_uri.at(1), 'wrong token uri (part 2)'
    );
    assert(
        *token_uri_array.at(2) == *base_uri.at(2), 'wrong token uri (part 3)'
    );
    assert(*token_uri_array.at(3) == '150', 'wrong token uri (token id)');
    assert(*token_uri_array.at(4) == '.json', 'wrong token uri (suffix)');
}

#[test]
#[available_gas(2000000000)]
fn test_mint_all_amount() {
    let owner = contract_address_const::<123>();
    set_contract_address(owner);

    let (contract, _, _) = deploy(owner, 'Token', 'T', 300);

    let recipient = contract_address_const::<1>();
    contract.mint(recipient, 300);
}

#[test]
#[should_panic]
#[available_gas(2000000000)]
fn test_mint_not_admin() {
    let admin = contract_address_const::<1>();
    set_contract_address(admin);

    let (contract, _, _) = deploy(admin, 'Token', 'T', 300);

    let not_admin = contract_address_const::<2>();
    set_contract_address(not_admin);

    contract.mint(not_admin, 100);
}

#[test]
#[should_panic]
#[available_gas(2000000000)]
fn test_mint_too_much() {
    let (contract, _, _) = deploy(contract_address_const::<123>(), 'Token', 'T', 300);
    contract.mint(get_contract_address(), 301);
}

#[test]
#[ignore]
#[available_gas(2000000000)]
fn test_can_upgrade() {
    let owner = contract_address_const::<123>();
    set_contract_address(owner);

    let (contract, _, upgradeable) = deploy(owner, 'Token', 'T', 300);

    // TODO make it work actually
    let new_class_hash = class_hash_const::<234>();
    upgradeable.upgrade(new_class_hash);
}
