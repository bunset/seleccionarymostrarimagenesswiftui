import SwiftUI
import PhotosUI

struct ContentView: View {
    // Estado para almacenar las imágenes seleccionadas
    @State private var images: [UIImage] = []
    // Estado para controlar la presentación del selector de imágenes
    @State private var isShowingImagePicker = false
    
    var body: some View {
        VStack {
            // Verificar si hay imágenes seleccionadas
            if !images.isEmpty {
                // Mostrar un ScrollView si hay imágenes
                ScrollView {
                    // Mostrar las imágenes en un LazyVGrid para un desplazamiento eficiente
                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
                        ForEach(images, id: \.self) { image in
                            // Mostrar cada imagen en una vista Image, escalable y ajustable
                            Image(uiImage: image)
                                .resizable()
                                .scaledToFit()
                        }
                    }
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
            ImagePicker(images: $images)
        }
        .padding()
    }
}

// Representación de un controlador de vista de selección de imágenes
struct ImagePicker: UIViewControllerRepresentable {
    // Enlace para almacenar las imágenes seleccionadas
    @Binding var images: [UIImage]
    
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
                // Verificar si se puede cargar una imagen
                if result.itemProvider.canLoadObject(ofClass: UIImage.self) {
                    // Cargar la imagen
                    result.itemProvider.loadObject(ofClass: UIImage.self) { (image, error) in
                        // Verificar si se pudo cargar la imagen
                        if let image = image as? UIImage {
                            // Actualizar el estado de las imágenes en el hilo principal
                            DispatchQueue.main.async {
                                self.parent.images.append(image)
                            }
                        }
                    }
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
