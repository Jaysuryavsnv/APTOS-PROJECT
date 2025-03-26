module MyModule::StablecoinMinter {
    use std::signer;
    use aptos_framework::coin;
    use aptos_framework::account;
    
    /// Struct representing the stablecoin
    struct StableCoin has key, store {}
    
    /// Struct for storing minting capabilities
    struct MinterCapability has key {
        mint_cap: coin::MintCapability<StableCoin>,
        burn_cap: coin::BurnCapability<StableCoin>,
    }
    
    /// Initialize the stablecoin with a fixed total supply
    public fun initialize(admin: &signer) {
        // Create a new coin type
        let (burn_cap, freeze_cap, mint_cap) = coin::initialize<StableCoin>(
            admin,
            string::utf8(b"USDStable"),
            string::utf8(b"USDST"),
            8, // decimals
            true // monitor supply
        );
        
        // Store minting capabilities
        move_to(admin, MinterCapability {
            mint_cap,
            burn_cap,
        });
        
        // Destroy freeze capability as we're not using it
        coin::destroy_freeze_cap(freeze_cap);
    }
    
    /// Mint new stablecoins to a specified address
    public fun mint_stablecoin(
        minter: &signer, 
        recipient: address, 
        amount: u64
    ) acquires MinterCapability {
        // Validate that only the admin can mint
        let minter_addr = signer::address_of(minter);
        assert!(exists<MinterCapability>(minter_addr), 1);
        
        // Borrow minting capability
        let minter_cap = borrow_global<MinterCapability>(minter_addr);
        
        // Mint coins to the recipient
        let coins = coin::mint(amount, &minter_cap.mint_cap);
        coin::deposit(recipient, coins);
    }
}