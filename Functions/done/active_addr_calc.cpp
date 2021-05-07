#include <iostream>
#include <fstream>

using namespace std;

int main(int argc, char **argv){

	if(argc == 1){
		ifstream objfile(argv[0]);
		system("readelf --verbose > linker_script");
		ifstream scriptfile("linker_script");
		if(file &){
			
		}
	}

	return 0;
}