
/*
 Copyright (C) 2016 Apple Inc. All Rights Reserved.
 See LICENSE.txt for this sample’s licensing information
 
 Abstract:
 Shader compiler and linker utilities
 */

#include <stdlib.h>
#include <stdio.h>
#include <string.h>
#include <sys/stat.h>
#include "ShaderUtilities.h"

#define LogInfo printf
#define LogError printf

#define GLlog(format,...)           printf(format,__VA_ARGS__)

/* Compile a shader from the provided source(s) */
GLint glueCompileShader(GLenum target, GLsizei count, const GLchar **sources, GLuint *shader)
{
	GLint status;
    
	*shader = glCreateShader(target);	
	glShaderSource(*shader, count, sources, NULL);
	glCompileShader(*shader);
    
#if defined(DEBUG)
    GLint logLength = 0;
	glGetShaderiv(*shader, GL_INFO_LOG_LENGTH, &logLength);
	if (logLength > 0)
	{
		GLchar *log = (GLchar *)malloc(logLength);
		glGetShaderInfoLog(*shader, logLength, &logLength, log);
		LogInfo("Shader compile log:\n%s", log);
		free(log);
	}
#endif
    
	glGetShaderiv(*shader, GL_COMPILE_STATUS, &status);
	if (status == 0)
	{
		int i;
		
		LogError("Failed to compile shader:\n");
		for (i = 0; i < count; i++)
			LogInfo("%s", sources[i]);	
	}
	
	return status;
}


/* Link a program with all currently attached shaders */
GLint glueLinkProgram(GLuint program)
{
	GLint status;
	
	glLinkProgram(program);
	
#if defined(DEBUG)
    GLint logLength = 0;
    glGetProgramiv(program, GL_INFO_LOG_LENGTH, &logLength);
	if (logLength > 0)
	{
		GLchar *log = (GLchar *)malloc(logLength);
		glGetProgramInfoLog(program, logLength, &logLength, log);
		LogInfo("Program link log:\n%s", log);
		free(log);
	}
#endif
    
	glGetProgramiv(program, GL_LINK_STATUS, &status);
	if (status == 0)
		LogError("Failed to link program %d", program);
	
	return status;
}


/* Validate a program (for i.e. inconsistent samplers) */
GLint glueValidateProgram(GLuint program)
{
	GLint status;
	
	glValidateProgram(program);
    
#if defined(DEBUG)
    GLint logLength = 0;
	glGetProgramiv(program, GL_INFO_LOG_LENGTH, &logLength);
	if (logLength > 0)
	{
		GLchar *log = (GLchar *)malloc(logLength);
		glGetProgramInfoLog(program, logLength, &logLength, log);
		LogInfo("Program validate log:\n%s", log);
		free(log);
	}
#endif
    
	glGetProgramiv(program, GL_VALIDATE_STATUS, &status);
	if (status == 0)
		LogError("Failed to validate program %d", program);
	
	return status;
}


/* Return named uniform location after linking */
GLint glueGetUniformLocation(GLuint program, const GLchar *uniformName)
{
    GLint loc;
    
    loc = glGetUniformLocation(program, uniformName);
    
    return loc;
}


/* Convenience wrapper that compiles, links, enumerates uniforms and attribs */
GLint glueCreateProgram(const GLchar *vertSource, const GLchar *fragSource,
                        GLsizei attribNameCt, const GLchar **attribNames, 
                        const GLint *attribLocations,
                        GLsizei uniformNameCt, const GLchar **uniformNames, 
                        GLint *uniformLocations,
                        GLuint *program)
{
	GLuint vertShader = 0, fragShader = 0, prog = 0, status = 1, i;
	
    // Create shader program
	prog = glCreateProgram();
    
    // Create and compile vertex shader
	status *= glueCompileShader(GL_VERTEX_SHADER, 1, &vertSource, &vertShader);
    
    // Create and compile fragment shader
	status *= glueCompileShader(GL_FRAGMENT_SHADER, 1, &fragSource, &fragShader);
    
    // Attach vertex shader to program
	glAttachShader(prog, vertShader);
    
    // Attach fragment shader to program
	glAttachShader(prog, fragShader);
	
    // Bind attribute locations
    // This needs to be done prior to linking
	for (i = 0; i < attribNameCt; i++)
	{
		if(strlen(attribNames[i]))
			glBindAttribLocation(prog, attribLocations[i], attribNames[i]);
	}
	
    // Link program
	status *= glueLinkProgram(prog);
    
    // Get locations of uniforms
	if (status)
	{	
        for(i = 0; i < uniformNameCt; i++)
		{
            if(strlen(uniformNames[i]))
			    uniformLocations[i] = glueGetUniformLocation(prog, uniformNames[i]);
		}
		*program = prog;
	}
    
    // Release vertex and fragment shaders
	if (vertShader)
		glDeleteShader(vertShader);
	if (fragShader)
		glDeleteShader(fragShader);
    
	return status;
}
GLuint createGLProgramFromFile()
{
    const char* vBuffer =
    "attribute vec3 position;"
    "attribute vec3 color;"
    "attribute vec2 texcoord;"
    ""
    "varying vec2 v_texcoord;"
    ""
    "void main()"
    "{"
    "    const float degree = radians(0.0);"
    "    const mat3 rotate = mat3("
    "                             cos(degree), sin(degree), 0.0,"
    "                             -sin(degree), cos(degree), 0.0,"
    "                             0.0, 0.0, 1.0"
    "                             );"
    "    gl_Position = vec4(position, 1.0);"
    "    v_texcoord = texcoord;"
    "}";
    
    const char* fBuffer =
    "precision highp float;"
    ""
    "varying vec2 v_texcoord;"
    ""
    "uniform sampler2D image0;"
    "uniform sampler2D image1;"
    "uniform sampler2D image2;"
    ""
    "void main()"
    "{"
    "    highp float y = texture2D(image0, v_texcoord).r;"
    "    highp float u = texture2D(image1, v_texcoord).r - 0.5;"
    "    highp float v = texture2D(image2, v_texcoord).r - 0.5;"
    "    highp float r = y + 1.402 * v;"
    "    highp float g = y - 0.344 * u - 0.714 * v;"
    "    highp float b = y + 1.772 * u;"
    "    gl_FragColor = vec4(r, g, b, 1.0);"
    "}";
    
    return createGLProgram(vBuffer, fBuffer);
}
GLuint createGLProgram(const char *vertext, const char *frag)
{
    GLuint program = glCreateProgram();
    
    GLuint vertShader = createGLShader(vertext, GL_VERTEX_SHADER);
    GLuint fragShader = createGLShader(frag, GL_FRAGMENT_SHADER);
    
    if (vertShader == 0 || fragShader == 0) {
        return 0;
    }
    
    glAttachShader(program, vertShader);
    glAttachShader(program, fragShader);
    
    glLinkProgram(program);
    GLint success;
    glGetProgramiv(program, GL_LINK_STATUS, &success);
    if (!success) {
        GLint infoLen;
        glGetProgramiv(program, GL_INFO_LOG_LENGTH, &infoLen);
        if (infoLen > 1) {
            GLchar *infoText = (GLchar *)malloc(sizeof(GLchar)*infoLen + 1);
            if (infoText) {
                memset(infoText, 0x00, sizeof(GLchar)*infoLen + 1);
                glGetProgramInfoLog(program, infoLen, NULL, infoText);
                GLlog("%s", infoText);
                free(infoText);
            }
        }
        glDeleteShader(vertShader);
        glDeleteShader(fragShader);
        glDeleteProgram(program);
        return 0;
    }
    
    glDetachShader(program, vertShader);
    glDetachShader(program, fragShader);
    glDeleteShader(vertShader);
    glDeleteShader(fragShader);
    
    return program;
}
GLuint createGLShader(const char *shaderText, GLenum shaderType)
{
    GLuint shader = glCreateShader(shaderType);
    glShaderSource(shader, 1, &shaderText, NULL);
    glCompileShader(shader);
    
    int compiled = 0;
    glGetShaderiv(shader, GL_COMPILE_STATUS, &compiled);
    if (!compiled) {
        GLint infoLen = 0;
        glGetShaderiv (shader, GL_INFO_LOG_LENGTH, &infoLen);
        if (infoLen > 1) {
            char *infoLog = (char *)malloc(sizeof(char) * infoLen);
            if (infoLog) {
                glGetShaderInfoLog (shader, infoLen, NULL, infoLog);
                GLlog("Error compiling shader: %s\n", infoLog);
                free(infoLog);
            }
        }
        glDeleteShader(shader);
        return 0;
    }
    
    return shader;
}
GLuint createTexture2D(GLenum format, int width, int height, void *data)
{
    GLuint texture;
    glGenTextures(1, &texture);
    glBindTexture(GL_TEXTURE_2D, texture);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
    glTexImage2D(GL_TEXTURE_2D, 0, format, width, height, 0, format, GL_UNSIGNED_BYTE, data);
    
    glBindTexture(GL_TEXTURE_2D, 0);
    return texture;
}
