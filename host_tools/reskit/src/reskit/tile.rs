use image::{ GenericImageView, DynamicImage };
use std::fs;
use std::process::exit;

pub struct TilesetGenerator {
    image: DynamicImage,
    palette: Vec< u16 >
}

impl TilesetGenerator {

    pub fn new( filename: &str ) -> Result< TilesetGenerator, &'static str > {
        let dynamic_image = match image::open( filename ) {
            Ok( img ) => {
                // Image dimensions must be a multiple of 8
                let ( x, y ) = img.dimensions();
                if x % 8 == 0 && y % 8 == 0 {
                    img
                } else {
                    return Err( "Image dimensions not multiple of 8!" )
                }
            },
            Err( _ ) => return Err( "Could not open image file!" )
        };

        let mut default_palette = Vec::new();
        default_palette.push( 0x0000 );

        Ok( TilesetGenerator {
            image: dynamic_image,
            palette: default_palette
        } )
    }

    fn get_nearest_colour( &mut self, r: u16, g: u16, b: u16 ) -> usize {
        // Take upper byte of each colour and move them into the correct BGR location
        let final_val =
            ( ( r & 0x00F0 ) >> 4 ) |
              ( g & 0x00F0 ) |
            ( ( b & 0x00F0 ) << 4 );

        for i in 0..self.palette.len() {
            if self.palette[ i ] == final_val {
                return i
            }
        }

        if self.palette.len() == 16 {
            println!( "fatal: Image contains more than 16 colours...stopping." );
            exit( 2 );
        }

        self.palette.push( final_val );
        self.palette.len() - 1
    }

    pub fn generate( &mut self, outfile: &str ) -> i32 {
        let mut result = String::new();
        result += "OutputPattern:\n";

        // take self.image and split it into tiles, saving them to outfile
        let ( max_x, max_y ) = self.image.dimensions();

        for y in ( 0..max_y ).step_by( 8 ) {
            for x in ( 0..max_x ).step_by( 8 ) {
                let mut segment = String::new();

                for cell_y in 0..8 {
                    segment += "\tdc.l $";
                    for cell_x in 0..8 {
                        let pixel = self.image.get_pixel( cell_x + x, cell_y + y );

                        segment += &format!( "{:X}", self.get_nearest_colour( pixel[ 0 ].into(), pixel[ 1 ].into(), pixel[ 2 ].into() ) );
                    }
                    segment += "\n";
                }

                result += &( segment + "\n" );
            }
        }

        result += "\nOutputPalette:\n";
        for num in &self.palette {
            result += &format!( "\tdc.w ${:01$x}\n", num, 4 );
        }

        match fs::write( outfile, result ) {
            Ok( _ ) => 1,
            Err( _ ) => {
                println!( "fatal: Could not write file!" );
                4
            }
        }
    }

}
