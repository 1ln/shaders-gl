#pragma once

#include <glad/glad.h>

#include <string>
#include <fstream>
#include <sstream>
#include <iostream>

class Shader {

public:

Shader(const char* vertPath,const char* fragPath); 

void use();

void setBool(const std::string &name,bool value) const;
void setInt(const std::string &name,int value) const;
void setFloat(const std::string &name,int value) const;

unsigned int id;

private:

void checkCompileErrors(unsigned int shader,std::string type);

}