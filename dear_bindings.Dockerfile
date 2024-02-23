# syntax=docker/dockerfile:1
FROM alpine AS sources
WORKDIR /dear_bindings
RUN apk update
RUN apk add git
RUN apk add openssh-client
RUN git clone https://github.com/dearimgui/dear_bindings.git .

RUN git clone https://github.com/ocornut/imgui.git imgui

FROM python AS generator
WORKDIR /dear_bindings
COPY --from=sources /dear_bindings .
RUN pip3 install ply

RUN python3 dear_bindings.py --output cimgui imgui/imgui.h --generateunformattedfunctions

FROM ubuntu:20.04 AS compile-windows
WORKDIR /cimgui
COPY --from=generator /dear_bindings .

RUN apt-get update
RUN apt-get install -y cmake mingw-w64


# https://github.com/cimgui/cimgui/blob/master/Makefile uses -Wall, but we don't need warnings
# https://github.com/ImGuiNET/ImGui.NET-nativebuild/blob/master/build-native.sh IMGUI_USE_WCHAR32 is not required
RUN x86_64-w64-mingw32-gcc \
-std=c++11 \
-shared \
-DIMGUI_IMPL_API='extern "C" __declspec(dllexport)' \
-DIMGUI_STATIC \
-DIMGUI_DISABLE_OBSOLETE_FUNCTIONS=1 \
-O2 -fno-exceptions -fno-rtti \
-fno-threadsafe-statics \
-o cimgui.dll \
-I. \
-Iimgui \
-limm32 \
-lstdc++ \
-x c++ cimgui.cpp \
imgui/imgui.cpp \
imgui/imgui_demo.cpp \
imgui/imgui_draw.cpp \
imgui/imgui_tables.cpp \
imgui/imgui_widgets.cpp \
-lm 

FROM gcc AS compile-linux
WORKDIR /cimgui
COPY --from=generator /dear_bindings .

# https://github.com/cimgui/cimgui/blob/master/Makefile uses -Wall, but we don't need warnings
# https://github.com/ImGuiNET/ImGui.NET-nativebuild/blob/master/build-native.sh IMGUI_USE_WCHAR32 is not required
RUN gcc \
-std=c++11 \
-shared -fPIC \
-DIMGUI_IMPL_API=extern"C" \
-DIMGUI_STATIC \
-DIMGUI_DISABLE_OBSOLETE_FUNCTIONS=1 \
-O2 -fno-exceptions -fno-rtti \
-fno-threadsafe-statics \
-o cimgui.so \
-Iimgui -I. \
-Wall \
-x c++ cimgui.cpp \
imgui/imgui.cpp \
imgui/imgui_demo.cpp \
imgui/imgui_draw.cpp \
imgui/imgui_tables.cpp \
imgui/imgui_widgets.cpp \
-lm -lstdc++ 

FROM alpine AS final
COPY --from=compile-linux /cimgui/cimgui.so /final/cimgui.so
COPY --from=compile-windows /cimgui/cimgui.dll /final/cimgui.dll
COPY --from=generator /dear_bindings/cimgui.json /final/cimgui.json
COPY --from=generator /dear_bindings/cimgui.h /final/cimgui.h
COPY --from=generator /dear_bindings/cimgui.cpp /final/cimgui.cpp

RUN echo "Success"

CMD ["/bin/cp", "-r", "/final/.", "/cimgui_build"]