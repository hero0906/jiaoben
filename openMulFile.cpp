#include <unistd.h>
#include <stdio.h>
#include <fcntl.h>
#include <errno.h>
#include <iostream>
#include <string>

using namespace std;

int main(int argc, char* argv[])
{
   if (argc != 2) {
      cout << "invalid arg" << endl;
      return -2;
   }
   
   string basePath = argv[1];
   auto i = 0;
   for (; i<1000; i++) {
      string fileName = "file" + to_string(i);
      string filePath = basePath + "/" + fileName;
      int fd = open(filePath.c_str(), O_RDWR | O_CREAT, 0777);
      if (fd < 0) {
         cout << "open failed " << errno << endl;
         return -1;
      }
   }

   cout << i << " open done"<< endl;
   while (1) {
      sleep(1000);
   }

   return 0;
}