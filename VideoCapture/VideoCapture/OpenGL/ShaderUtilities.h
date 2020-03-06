
/*
 Copyright (C) 2016 Apple Inc. All Rights Reserved.
 See LICENSE.txt for this sample’s licensing information
 
 Abstract:
 Shader compiler and linker utilities
 */


#ifndef RosyWriter_ShaderUtilities_h
#define RosyWriter_ShaderUtilities_h
    
#include <OpenGLES/ES2/gl.h>
#include <OpenGLES/ES2/glext.h>

GLint glueCompileShader(GLenum target, GLsizei count, const GLchar **sources, GLuint *shader);
GLint glueLinkProgram(GLuint program);
GLint glueValidateProgram(GLuint program);
GLint glueGetUniformLocation(GLuint program, const GLchar *name);

GLint glueCreateProgram(const GLchar *vertSource, const GLchar *fragSource,
                        GLsizei attribNameCt, const GLchar **attribNames, 
                        const GLint *attribLocations,
                        GLsizei uniformNameCt, const GLchar **uniformNames,
                        GLint *uniformLocations,
                        GLuint *program);
GLuint createGLProgramFromFile(void);
GLuint createGLProgram(const char *vertext, const char *frag);
GLuint createGLShader(const char *shaderText, GLenum shaderType);
GLuint createTexture2D(GLenum format, int width, int height, void *data);
#endif
