use starknet::ContractAddress;

#[starknet::interface]
trait INFT<TContractState> {
    // Standard ERC721 + ERC721Metadata methods
    fn name(self: @TContractState) -> felt252;
    fn symbol(self: @TContractState) -> felt252;
    fn token_uri(self: @TContractState, token_id: u256) -> Array<felt252>;
    fn supports_interface(self: @TContractState, interface_id: felt252) -> bool;
    fn balance_of(self: @TContractState, account: ContractAddress) -> u256;
    fn owner_of(self: @TContractState, token_id: u256) -> ContractAddress;
    fn get_approved(self: @TContractState, token_id: u256) -> ContractAddress;
    fn is_approved_for_all(
        self: @TContractState, owner: ContractAddress, operator: ContractAddress
    ) -> bool;
    fn approve(ref self: TContractState, to: ContractAddress, token_id: u256);
    fn set_approval_for_all(ref self: TContractState, operator: ContractAddress, approved: bool);
    fn transfer_from(
        ref self: TContractState, from: ContractAddress, to: ContractAddress, token_id: u256
    );
    fn safe_transfer_from(
        ref self: TContractState,
        from: ContractAddress,
        to: ContractAddress,
        token_id: u256,
        data: Span<felt252>
    );
    // camelCase methods that duplicate the main snake_case interface for compatibility
    fn tokenURI(self: @TContractState, tokenId: u256) -> Array<felt252>;
    fn supportsInterface(self: @TContractState, interfaceId: felt252) -> bool;
    fn balanceOf(self: @TContractState, account: ContractAddress) -> u256;
    fn ownerOf(self: @TContractState, tokenId: u256) -> ContractAddress;
    fn getApproved(self: @TContractState, tokenId: u256) -> ContractAddress;
    fn isApprovedForAll(
        self: @TContractState, owner: ContractAddress, operator: ContractAddress
    ) -> bool;
    fn setApprovalForAll(ref self: TContractState, operator: ContractAddress, approved: bool);
    fn transferFrom(
        ref self: TContractState, from: ContractAddress, to: ContractAddress, tokenId: u256
    );
    fn safeTransferFrom(
        ref self: TContractState,
        from: ContractAddress,
        to: ContractAddress,
        tokenId: u256,
        data: Span<felt252>
    );
    // Non-standard method for minting new NFTs. Can be called by admin only
    fn mint(ref self: TContractState, recipient: ContractAddress, amount: u256);
    // methods for retrieving supply
    fn max_supply(self: @TContractState) -> u256;
    fn total_supply(self: @TContractState) -> u256;
    // and their camelCase equivalents
    fn maxSupply(self: @TContractState) -> u256;
    fn totalSupply(self: @TContractState) -> u256;
    // method for setting base URI common for all tokens
}
