import SwiftUI
import PhotosUI

struct ContentView: View {
    // Estado para almacenar los nombres de archivo de las imágenes seleccionadas
    @State private var imageFileNames: [String] = []
    // Estado para controlar la presentación del selector de imágenes
    @State private var isShowingImagePicker = false
    
    var body: some View {
        VStack {
            // Verificar si hay nombres de archivo de imágenes seleccionadas
            if !imageFileNames.isEmpty {
                // Mostrar una lista con los nombres de archivo
                List(imageFileNames, id: \.self) { fileName in
                    Text(fileName)
                }
            } else {
                // Mostrar un mensaje si no hay imágenes seleccionadas
                Text("No hay imágenes seleccionadas")
                    .foregroundColor(.gray)
            }
            
            // Botón para abrir el selector de imágenes
            Button(action: {
                isShowingImagePicker.toggle()
            }) {
                Text("Seleccionar imágenes")
                    .padding()
                    .foregroundColor(.white)
                    .background(Color.blue)
                    .cornerRadius(10)
            }
        }
        .sheet(isPresented: $isShowingImagePicker) {
            // Presentar el selector de imágenes en un sheet
            ImagePicker(imageFileNames: $imageFileNames)
        }
        .padding()
    }
}

// Representación de un controlador de vista de selección de imágenes
struct ImagePicker: UIViewControllerRepresentable {
    // Enlace para almacenar los nombres de archivo de las imágenes seleccionadas
    @Binding var imageFileNames: [String]
    
    // Método para crear el coordinador
    func makeCoordinator() -> Coordinator {
        Coordinator(parent: self)
    }
    
    // Método para crear el controlador de vista de selección de imágenes
    func makeUIViewController(context: Context) -> PHPickerViewController {
        // Configuración del selector de imágenes
        var configuration = PHPickerConfiguration()
        configuration.filter = .images
        configuration.selectionLimit = 0 // Permite seleccionar un número ilimitado de imágenes
        
        // Crear y configurar el controlador de vista de selección de imágenes
        let picker = PHPickerViewController(configuration: configuration)
        picker.delegate = context.coordinator
        return picker
    }
    
    // Método para actualizar el controlador de vista de selección de imágenes
    func updateUIViewController(_ uiViewController: PHPickerViewController, context: Context) {}
    
    // Coordinador para manejar los eventos del selector de imágenes
    class Coordinator: NSObject, PHPickerViewControllerDelegate {
        let parent: ImagePicker
        
        init(parent: ImagePicker) {
            self.parent = parent
        }
        
        // Método llamado cuando se seleccionan imágenes
        func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
            // Cerrar el selector de imágenes
            picker.dismiss(animated: true)
            
            // Iterar sobre los resultados de la selección
            for result in results {
                // Obtener el nombre de archivo de la imagen seleccionada
                var fileName = "Imagen sin nombre"
                
                if let assetIdentifier = result.assetIdentifier {
                    fileName = assetIdentifier
                } else if let fileNameFromURL = result.itemProvider.suggestedName {
                    fileName = fileNameFromURL
                }
                
                // Actualizar el estado de los nombres de archivo en el hilo principal
                DispatchQueue.main.async {
                    self.parent.imageFileNames.append(fileName)
                }
            }
        }
    }
}

// Vista previa de ContentView
struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}

