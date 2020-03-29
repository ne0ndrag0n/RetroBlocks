extern crate image;
use std::env::args;
use std::process::exit;

mod reskit;
use reskit::tile::TilesetGenerator;

fn print_help() {
    println!( "Usage:" );
    println!( "\treskit [plugin] filename_in filename_out" );
}

fn check( potential_message: Option< String > ) -> String {
    match potential_message {
        Some( string ) => string,
        None => {
            println!( "fatal: missing expected value" );
            print_help();
            exit( 2 );
        }
    }
}

fn check_module< T >( potential: Result< T, &'static str > ) -> T {
    match potential {
        Ok( product ) => product,
        Err( message ) => {
            println!( "fatal: Failed to init module: {}", message );
            exit( 3 );
        }
    }
}

fn main() {
    println!( "reskit - IndigoHedgehog Resource Kit v0.0.1a" );
    println!( "(c) 2018-2019 ne0ndrag0n novelties" );

    let mut args = args();

    // Burn arg1
    args.next();

    let mode = match args.next() {
        Some( mode ) => mode,
        None => {
            print_help();
            exit( 1 );
        }
    };

    exit(
        match mode.as_str() {
            "tileset" => check_module( TilesetGenerator::new( &check( args.next() ) ) ).generate( &check( args.next() ) ),
            _ => {
                println!( "fatal: Unknown module: {}", mode );
                5
            }
        }
    );
}
