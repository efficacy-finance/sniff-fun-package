module sniff_dot_fun::admin {

    const EAdminAccessNotInitialised: u64 = 0;

    public struct AdminAccess has key {
        id: UID,
        admin_1: address
    }

    public struct AdminCap has key, store {
        id: UID,
        admin_id: u8
    }

    fun init(ctx: &mut TxContext) {
        transfer::share_object(AdminAccess { 
            id: object::new(ctx),
            admin_1: @0x0
        });

        // create admin caps.
        let admin_cap_1 = AdminCap {
            id: object::new(ctx),
            admin_id: 1
        };
    
        transfer::transfer(admin_cap_1, tx_context::sender(ctx));
    }

    public fun update_address(self: &mut AdminAccess, cap: &AdminCap, val: address, _ctx: &mut TxContext){
        self.admin_1 = val;
    }

    public fun get_addresses(self: &AdminAccess): (address) {
        assert_initialised(self);
        (self.admin_1)
    }

    public fun assert_initialised(self: &AdminAccess) {
        assert!(self.admin_1 != @0x0, EAdminAccessNotInitialised);
    }
}