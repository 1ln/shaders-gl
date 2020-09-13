#include "Shader.h"

Shader::Shader(const char* vertPath,const char* fragPath) {

    std::string vertCode;
    std::string fragCode;

    std::ifstream vShaderFile;
    std::ifstream fShaderFile;

    vShaderFile.exception (std::ifstream::failbit | std::ifstream::badbit);
    fShaderFile.exception (std::ifstream::failbit | std::ifstream::badbit);

    try {

        vShaderFile.open(vertPath);
        fShaderFile.open(fragPath);

        std::stringstream vShaderStream, fShaderStream;

        vShaderStream << vShaderFile.rdbuf();
        fShaderStream << fShaderFile.rdbuf();

        vShaderFile.close();
        fShaderFile.close();

        vertCode = vShaderStream.str();
        fragCode = fShaderStream.str();

    }

    catch(std::ifstream::failure& e) {
       std::cout << "Error, shader could not be read" << std::endl;
    }

    const char* vShaderCode = vertCode.c_str();
    const char* fShaderCode = fragCode.c_str();

    unsigned int vert,frag;

    vert = glCreateShader(GL_VERTEX_SHADER);
    glShaderSource(vert,1,&vShaderCode,NULL);
    glCompileShader(vert);
    checkCompileErrors(vert,"VERTEX");

    frag = glCreateShader(GL_FRAGMENT_SHADER);
    glShaderSource(frag,1,&fShaderCode,NULL);
    glCompileShader(frag);
    checkCompileErrors(frag,"FRAGMENT");

    id = glCreateProgram();
    glAttachShader(id,vert);
    glAttachShader(id,frag);

    glLinkProgram(id);
    checkCompileErrors(id,"PROGRAM");
    
    glDeleteShader(vert);
    glDeletShader(frag);

}

void use() {

    glUseProgram(id);
}

void setBool(const std::string &name,bool value) const {

    glUniform1i(glGetUniformLocation(id,name.c_str()),(int)value);
}

void setInt(const std::string &name,int value) const {

    glUniform1i(glGetUniformLocation(id,name.c_str()),value);
}

void setFloat(const std::string &name,int value) const {

   glUniform1f(glGetUniformLocation(id,name.c_str()),value);
}

void checkCompileErrors(unsigned int shader,std::string type) {

    int success;
    char infoLog[1024];
  
    if(type != "PROGRAM") {

       glGetShaderiv(shader,GL_COMPILE_STATUS,&success);  

        if(!success) {
            glGetShaderInfoLog(shader,1024,NULL,infoLog);
            std::cout <<  "ERROR::type: "
            << type << "\n" << infoLog << std::endl; 

        }

    } else {
       
        glGetProgramiv(shader,GL_LINK_STATUS,&success);

        if(!success) {
            glGetProgramInfoLog(shader,1024,NULL,infoLog);
            std::cout << "ERROR::type: "
            << type << "\n" << infoLog << std::endl;

        }
    }
}