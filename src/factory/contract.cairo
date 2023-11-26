// NFT Factory deploys new nft collections
// It keeps a relevant class hash of an NFT collection contract

use super::interface::INFTFactory;

#[starknet::contract]
mod NFTFactory {
    use core::serde::Serde;
use core::starknet::event::EventEmitter;
use starknet::{ContractAddress, ClassHash, get_caller_address, deploy_syscall};
    use openzeppelin::access::ownable::Ownable as ownable_component;
    use openzeppelin::upgrades::upgradeable::Upgradeable as upgradeable_component;
    use openzeppelin::upgrades::interface::IUpgradeable;

    component!(path: ownable_component, storage: ownable, event: OwnableEvent);
    component!(path: upgradeable_component, storage: upgradeable, event: UpgradeableEvent);

    /// Ownable
    #[abi(embed_v0)]
    impl OwnableImpl = ownable_component::OwnableImpl<ContractState>;
    #[abi(embed_v0)]
    impl OwnableCamelOnlyImpl =
        ownable_component::OwnableCamelOnlyImpl<ContractState>;
    impl InternalImpl = ownable_component::InternalImpl<ContractState>;

    /// Upgradeable
    impl UpgradeableInternalImpl = upgradeable_component::InternalImpl<ContractState>;

    #[storage]
    struct Storage {
        nft_class_hash: ClassHash,
        // TODO: collections deployed by owners
        #[substorage(v0)]
        ownable: ownable_component::Storage,
        #[substorage(v0)]
        upgradeable: upgradeable_component::Storage
    }

    mod Errors {
        const NFT_CLASS_UNDEFINED: felt252 = 'NFT class hash is not defined';
    }

    #[event]
    #[derive(Drop, starknet::Event)]
    enum Event {
        NFTClassHashSet: NFTClassHashSet,
        CollectionDeployed: CollectionDeployed,
        #[flat]
        OwnableEvent: ownable_component::Event,
        #[flat]
        UpgradeableEvent: upgradeable_component::Event,
    }

    #[derive(Drop, starknet::Event)]
    struct NFTClassHashSet {
        #[key]
        old_hash: ClassHash,
        #[key]
        new_hash: ClassHash,
    }

    #[derive(Drop, starknet::Event)]
    struct CollectionDeployed {
        #[key]
        owner: ContractAddress,
        #[key]
        collection: ContractAddress,
    }

    #[constructor]
    fn constructor(
        ref self: ContractState,
        admin: ContractAddress,
    ) {
        self.ownable.initializer(admin);
    }

    #[external(v0)]
    impl UpgradeableImpl of IUpgradeable<ContractState> {
        fn upgrade(ref self: ContractState, new_class_hash: ClassHash) {
            // This function can only be called by the owner
            self.ownable.assert_only_owner();

            // Replace the class hash upgrading the contract
            self.upgradeable._upgrade(new_class_hash);
        }
    }

    #[external(v0)]
    impl NFTFactoryImpl of super::INFTFactory<ContractState> {
        fn set_nft_class_hash(ref self: ContractState, new_nft_class_hash: ClassHash) {
            self.ownable.assert_only_owner();
            self.nft_class_hash.write(new_nft_class_hash);
        }
        // TODO settings or flags
        fn deploy_collection(
            ref self: ContractState,
            name: felt252,
            symbol: felt252,
            max_supply: u256,
            base_uri: Array<felt252>,
        ) -> ContractAddress {
            let collection_owner = get_caller_address();
            // loading nft class hash (check non-zero)
            // get caller address (for passing it into nft contract constructor as its owner)
            // packing calldata
            // invoking deploy with calldata

            // Contructor arguments
            let mut constructor_calldata: Array::<felt252> = array![
                collection_owner.into(),
                name,
                symbol,
            ];
            max_supply.serialize(ref constructor_calldata);
            base_uri.serialize(ref constructor_calldata);

            // Contract deployment
            let (deployed_address, _) = deploy_syscall(
                self.nft_class_hash.read(), 0, constructor_calldata.span(), false
            )
                .expect('failed to deploy counter');


            self.emit(
                CollectionDeployed{
                    owner: collection_owner,
                    collection: deployed_address,
                }
            );

            deployed_address
        }
    }
}
