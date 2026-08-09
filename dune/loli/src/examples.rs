pub mod examples {
    pub fn bytes() -> () {
        let mut byte: u8 = 0b0000_0000;
    
        byte |= 0b0000_1000; // Set a bit
        println!("0b{:08b}", byte);
    
        byte &= 0b1111_0111; // Unset a bit
        println!("0b{:08b}", byte);
    
        byte ^= 0b0000_1000; // Toggle a bit
        println!("0b{:08b}", byte);
    }
}
