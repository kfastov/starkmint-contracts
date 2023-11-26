use starknet::ContractAddress;
use starknet::ClassHash;

// states:
// uninitialized -> initialized <-> frozen
// uninitialized, frozen: can't deploy collections
// uninitialized + nft class set -> initialized
// initialized: can deploy collections

#[starknet::interface]
trait INFTFactory<TContractState> {
    fn set_nft_class_hash(ref self: TContractState, new_nft_class_hash: ClassHash);
    fn deploy_collection(
        ref self: TContractState,
        name: felt252,
        symbol: felt252,
        max_supply: u256,
        base_uri: Array<felt252>,
    ) -> ContractAddress;
}
