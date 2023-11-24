use super::interface::INFT;

#[starknet::contract]
mod NFT {
    use starknet::ContractAddress;
    use starknet::ClassHash;
    use openzeppelin::token::erc721::ERC721;
    use array::ArrayTrait;
    use alexandria_ascii::integer::ToAsciiTrait;
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
        max_supply: u256,
        last_token_id: u256,
        base_uri_len: u32,
        base_uri: LegacyMap<u32, felt252>,
        #[substorage(v0)]
        ownable: ownable_component::Storage,
        #[substorage(v0)]
        upgradeable: upgradeable_component::Storage
    }

    mod Errors {
        const MINT_ZERO_AMOUNT: felt252 = 'mint amount should be >= 1';
        const MINT_AMOUNT_TOO_LARGE: felt252 = 'mint amount too large';
        const MINT_MAX_SUPPLY_EXCEEDED: felt252 = 'max supply exceeded';
    }

    #[event]
    #[derive(Drop, starknet::Event)]
    enum Event {
        Transfer: Transfer,
        Approval: Approval,
        ApprovalForAll: ApprovalForAll,
        #[flat]
        OwnableEvent: ownable_component::Event,
        #[flat]
        UpgradeableEvent: upgradeable_component::Event,
    }

    #[derive(Drop, starknet::Event)]
    struct Transfer {
        #[key]
        from: ContractAddress,
        #[key]
        to: ContractAddress,
        #[key]
        token_id: u256
    }

    #[derive(Drop, starknet::Event)]
    struct Approval {
        #[key]
        owner: ContractAddress,
        #[key]
        approved: ContractAddress,
        #[key]
        token_id: u256
    }

    #[derive(Drop, starknet::Event)]
    struct ApprovalForAll {
        #[key]
        owner: ContractAddress,
        #[key]
        operator: ContractAddress,
        approved: bool
    }

    #[constructor]
    fn constructor(
        ref self: ContractState,
        admin: ContractAddress,
        name: felt252,
        symbol: felt252,
        max_supply: u256
    ) {
        self.max_supply.write(max_supply);

        let mut unsafe_state = ERC721::unsafe_new_contract_state();
        ERC721::InternalImpl::initializer(ref unsafe_state, name, symbol);

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
    impl NFTImpl of super::INFT<ContractState> {
        fn name(self: @ContractState) -> felt252 {
            let unsafe_state = ERC721::unsafe_new_contract_state();
            ERC721::ERC721MetadataImpl::name(@unsafe_state)
        }

        fn symbol(self: @ContractState) -> felt252 {
            let unsafe_state = ERC721::unsafe_new_contract_state();
            ERC721::ERC721MetadataImpl::symbol(@unsafe_state)
        }

        fn token_uri(self: @ContractState, token_id: u256) -> Array<felt252> {
            let mut uri = ArrayTrait::new();

            // retrieve base_uri from the storage and append to the uri string
            let mut i = 0;
            loop {
                if i >= self.base_uri_len.read() {
                    break;
                }
                uri.append(self.base_uri.read(i));
                i += 1;
            };

            let token_id_ascii = token_id.to_ascii();

            let mut i = 0;
            loop {
                if i >= token_id_ascii.len() {
                    break;
                }
                uri.append(*token_id_ascii.at(i));
                i += 1;
            };

            uri.append('.json');
            uri
        }

        fn supports_interface(self: @ContractState, interface_id: felt252) -> bool {
            let unsafe_state = ERC721::unsafe_new_contract_state();
            ERC721::SRC5Impl::supports_interface(@unsafe_state, interface_id)
        }

        fn supportsInterface(self: @ContractState, interfaceId: felt252) -> bool {
            let unsafe_state = ERC721::unsafe_new_contract_state();
            ERC721::SRC5CamelImpl::supportsInterface(@unsafe_state, interfaceId)
        }

        fn tokenURI(self: @ContractState, tokenId: u256) -> Array<felt252> {
            NFTImpl::token_uri(self, tokenId)
        }

        fn balance_of(self: @ContractState, account: ContractAddress) -> u256 {
            let unsafe_state = ERC721::unsafe_new_contract_state();
            ERC721::ERC721Impl::balance_of(@unsafe_state, account)
        }

        fn owner_of(self: @ContractState, token_id: u256) -> ContractAddress {
            let unsafe_state = ERC721::unsafe_new_contract_state();
            ERC721::ERC721Impl::owner_of(@unsafe_state, token_id)
        }

        fn get_approved(self: @ContractState, token_id: u256) -> ContractAddress {
            let unsafe_state = ERC721::unsafe_new_contract_state();
            ERC721::ERC721Impl::get_approved(@unsafe_state, token_id)
        }

        fn is_approved_for_all(
            self: @ContractState, owner: ContractAddress, operator: ContractAddress
        ) -> bool {
            let unsafe_state = ERC721::unsafe_new_contract_state();
            ERC721::ERC721Impl::is_approved_for_all(@unsafe_state, owner, operator)
        }

        fn approve(ref self: ContractState, to: ContractAddress, token_id: u256) {
            let mut unsafe_state = ERC721::unsafe_new_contract_state();
            ERC721::ERC721Impl::approve(ref unsafe_state, to, token_id)
        }

        fn set_approval_for_all(
            ref self: ContractState, operator: ContractAddress, approved: bool
        ) {
            let mut unsafe_state = ERC721::unsafe_new_contract_state();
            ERC721::ERC721Impl::set_approval_for_all(ref unsafe_state, operator, approved)
        }

        fn transfer_from(
            ref self: ContractState, from: ContractAddress, to: ContractAddress, token_id: u256
        ) {
            let mut unsafe_state = ERC721::unsafe_new_contract_state();
            ERC721::ERC721Impl::transfer_from(ref unsafe_state, from, to, token_id)
        }

        fn safe_transfer_from(
            ref self: ContractState,
            from: ContractAddress,
            to: ContractAddress,
            token_id: u256,
            data: Span<felt252>
        ) {
            let mut unsafe_state = ERC721::unsafe_new_contract_state();
            ERC721::ERC721Impl::safe_transfer_from(ref unsafe_state, from, to, token_id, data)
        }

        fn balanceOf(self: @ContractState, account: ContractAddress) -> u256 {
            let unsafe_state = ERC721::unsafe_new_contract_state();
            ERC721::ERC721CamelOnlyImpl::balanceOf(@unsafe_state, account)
        }

        fn ownerOf(self: @ContractState, tokenId: u256) -> ContractAddress {
            let unsafe_state = ERC721::unsafe_new_contract_state();
            ERC721::ERC721CamelOnlyImpl::ownerOf(@unsafe_state, tokenId)
        }

        fn getApproved(self: @ContractState, tokenId: u256) -> ContractAddress {
            let unsafe_state = ERC721::unsafe_new_contract_state();
            ERC721::ERC721CamelOnlyImpl::getApproved(@unsafe_state, tokenId)
        }

        fn isApprovedForAll(
            self: @ContractState, owner: ContractAddress, operator: ContractAddress
        ) -> bool {
            let unsafe_state = ERC721::unsafe_new_contract_state();
            ERC721::ERC721CamelOnlyImpl::isApprovedForAll(@unsafe_state, owner, operator)
        }

        fn setApprovalForAll(ref self: ContractState, operator: ContractAddress, approved: bool) {
            let mut unsafe_state = ERC721::unsafe_new_contract_state();
            ERC721::ERC721CamelOnlyImpl::setApprovalForAll(ref unsafe_state, operator, approved)
        }

        fn transferFrom(
            ref self: ContractState, from: ContractAddress, to: ContractAddress, tokenId: u256
        ) {
            let mut unsafe_state = ERC721::unsafe_new_contract_state();
            ERC721::ERC721CamelOnlyImpl::transferFrom(ref unsafe_state, from, to, tokenId)
        }

        fn safeTransferFrom(
            ref self: ContractState,
            from: ContractAddress,
            to: ContractAddress,
            tokenId: u256,
            data: Span<felt252>
        ) {
            let mut unsafe_state = ERC721::unsafe_new_contract_state();
            ERC721::ERC721CamelOnlyImpl::safeTransferFrom(ref unsafe_state, from, to, tokenId, data)
        }

        // Non-standard method for minting new NFTs. Can be called by admin only
        fn mint(ref self: ContractState, recipient: ContractAddress, amount: u256) {
            // check if sender is the owner of the contract
            self.ownable.assert_only_owner();
            assert(amount > 0, Errors::MINT_ZERO_AMOUNT);
            // get the last id
            let last_token_id = self.last_token_id.read();
            // calculate the last id after mint (maybe use safe math if available)
            let last_mint_id = last_token_id + amount;
            // don't mint more than the preconfigured max supply
            let max_supply = self.max_supply.read();
            assert(last_mint_id <= max_supply, Errors::MINT_MAX_SUPPLY_EXCEEDED);
            // call mint sequentially
            let mut unsafe_state = ERC721::unsafe_new_contract_state();
            let mut token_id = last_token_id + 1;
            loop {
                if token_id > last_mint_id {
                    break;
                }
                ERC721::InternalImpl::_mint(ref unsafe_state, recipient, token_id);
                token_id += 1;
            };
            // Save the id of last minted token
            self.last_token_id.write(last_mint_id);
        }

        fn max_supply(self: @ContractState) -> u256 {
            self.max_supply.read()
        }

        fn total_supply(self: @ContractState) -> u256 {
            self.last_token_id.read()
        }

        fn maxSupply(self: @ContractState) -> u256 {
            NFTImpl::max_supply(self)
        }

        fn totalSupply(self: @ContractState) -> u256 {
            NFTImpl::total_supply(self)
        }

        fn set_base_uri(ref self: ContractState, base_uri: Array<felt252>) {
            // check if sender is the owner of the contract
            self.ownable.assert_only_owner();

            let base_uri_len = base_uri.len();
            let mut i = 0;
            self.base_uri_len.write(base_uri_len);
            loop {
                if i >= base_uri.len() {
                    break;
                }
                self.base_uri.write(i, *base_uri.at(i));
                i += 1;
            }
        }
    }
}
