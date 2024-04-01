namespace DearImguiGenerator;

public class CSharpManagedCodeGenerator
{
    private readonly List<CSharpStruct> _structs;

    public CSharpManagedCodeGenerator(List<CSharpStruct> structs)
    {
        _structs = structs;
    }

    public List<CSharpStruct> GenerateStructs()
    {
        List<CSharpStruct> result = [];
        
        foreach (var cStruct in _structs)
        {
            if (cStruct.Name != "ImGuiIO")
            {
                continue;
            }

            var sStruct = new CSharpStruct(cStruct.Name + "Managed");
            sStruct.Modifiers.Add("public");
            sStruct.Modifiers.Add("unsafe");
            var nativePtrProp = new CSharpProperty("NativePtr", new CSharpPointerType(new CSharpPrimitiveType(cStruct.Name)));
            nativePtrProp.Get = true;
            nativePtrProp.Modifiers.Add("public");
            sStruct.Properties.Add(nativePtrProp);

            var ptrCtor = new CSharpConstructor(sStruct.Name);
            ptrCtor.Arguments.Add(new CSharpArgument("nativePtr", new CSharpPointerType(new CSharpPrimitiveType(cStruct.Name))));
            ptrCtor.Body.Add("NativePtr = nativePtr;");
            ptrCtor.Modifiers.Add("public");
            sStruct.Constructors.Add(ptrCtor);

            var intptrCtor = new CSharpConstructor(sStruct.Name);
            intptrCtor.Arguments.Add(new CSharpArgument("nativePtr", new CSharpPrimitiveType("IntPtr")));
            intptrCtor.Body.Add($"NativePtr = ({cStruct.Name}*)nativePtr;");
            intptrCtor.Modifiers.Add("public");
            sStruct.Constructors.Add(intptrCtor);
            
            result.Add(sStruct);
        }
        
        return result;
    }
}