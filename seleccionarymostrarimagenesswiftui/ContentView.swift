import SwiftUI
import PDFKit

struct ContentView: View {
    // Estado para almacenar las imágenes seleccionadas
    @State private var selectedImages: [(UIImage, String)] = []
    // Estado para controlar la presentación del selector de imágenes
    @State private var isShowingImagePicker = false
    
    var body: some View {
        VStack {
            // si hay imágenes seleccionadas
            if !selectedImages.isEmpty {
                // Muestra una lista con nombres de archivo y miniaturas de imágenes
                List(selectedImages.indices, id: \.self) { index in
                    let (image, fileName) = selectedImages[index]
                    HStack {
                        Image(uiImage: image)
                            .resizable()
                            .frame(width: 50, height: 50)
                            .cornerRadius(5)
                        Text(fileName)
                    }
                }
                .padding(.bottom) // Añadir espacio en la parte inferior de la lista
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
            ImagePicker(selectedImages: $selectedImages)
        }
        .padding(.bottom)
        
        
        // Botón para crear y compartir el PDF
        Button(action: {
            createAndSharePDF()
        }) {
            Text("Crear y Compartir PDF")
                .padding()
                .foregroundColor(.white)
                .background(Color.green)
                .cornerRadius(10)
        }
        .padding(.top) // Añadir espacio en la parte superior del botón
        

        
    }
    
    // Función para crear y compartir el PDF
    private func createAndSharePDF() {
        print ("hola")
        let pdfDocument = PDFDocument()
        
        // Tamaño fijo para las imágenes en el PDF
        let imageSize = CGSize(width: 612, height: 792) // Tamaño de página estándar (8.5 x 11 pulgadas)
        
        // Agregar cada imagen seleccionada al documento PDF
        for (image, _) in selectedImages {
            // Redimensionar la imagen al tamaño fijo
            let resizedImage = resize(image: image, to: imageSize)
            
            if let pdfPage = PDFPage(image: resizedImage) {
                pdfDocument.insert(pdfPage, at: pdfDocument.pageCount)
            }
        }
        
        // Obtener la URL temporal del documento PDF
        let temporaryDirectoryURL = FileManager.default.temporaryDirectory
        let pdfURL = temporaryDirectoryURL.appendingPathComponent("combined_images.pdf")
        
        // Guardar el documento PDF en la URL temporal
        pdfDocument.write(to: pdfURL)
        
        // Crear y presentar un UIAlertController para solicitar el nombre del archivo
        let alertController = UIAlertController(title: "Nombre del archivo", message: "Introduce un nombre para el archivo PDF:", preferredStyle: .alert)
        
        alertController.addTextField { textField in
            textField.placeholder = "Nombre del archivo"
        }
        
        alertController.addAction(UIAlertAction(title: "Cancelar", style: .cancel))
        
        alertController.addAction(UIAlertAction(title: "Aceptar", style: .default) { _ in
            // Obtener el nombre ingresado por el usuario
            if let fileName = alertController.textFields?.first?.text {
                // Renombrar el archivo PDF con el nombre ingresado por el usuario
                let renamedPDFURL = temporaryDirectoryURL.appendingPathComponent("\(fileName).pdf")
                
                do {
                    // Intentar renombrar el archivo PDF
                    try FileManager.default.moveItem(at: pdfURL, to: renamedPDFURL)
                    
                    // Crear una instancia de la actividad de compartir
                    let activityViewController = UIActivityViewController(activityItems: [renamedPDFURL], applicationActivities: nil)
                    
                    // Presentar la actividad de compartir
                    if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
                       let window = windowScene.windows.first {
                        window.rootViewController?.present(activityViewController, animated: true, completion: nil)
                    }
                } catch {
                    print("Error al renombrar el archivo PDF: \(error.localizedDescription)")
                }
            }
        })
        
        // Presentar el UIAlertController
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let window = windowScene.windows.first {
            window.rootViewController?.present(alertController, animated: true)
        }
        
        // Eliminar archivos PDF antiguos
        deleteOldPDFs(in: temporaryDirectoryURL)

        
    }

    // Función para redimensionar una imagen al tamaño especificado manteniendo la relación de aspecto original
    private func resize(image: UIImage, to size: CGSize) -> UIImage {
        let aspectRatio = image.size.width / image.size.height
        
        var newSize = size
        if aspectRatio > 1 {
            newSize.height = size.width / aspectRatio
        } else {
            newSize.width = size.height * aspectRatio
        }
        
        UIGraphicsBeginImageContextWithOptions(newSize, false, 0.0)
        image.draw(in: CGRect(origin: .zero, size: newSize))
        let resizedImage = UIGraphicsGetImageFromCurrentImageContext()!
        UIGraphicsEndImageContext()
        return resizedImage
    }


    
    // Función para eliminar archivos PDF antiguos en la carpeta especificada
    private func deleteOldPDFs(in directoryURL: URL) {
        let fileManager = FileManager.default
        let fileURLs = try? fileManager.contentsOfDirectory(at: directoryURL, includingPropertiesForKeys: nil)
        
        if let fileURLs = fileURLs {
            for fileURL in fileURLs {
                if fileURL.pathExtension == "pdf" {
                    // Comprobar si el archivo PDF tiene antigüedad
                    if let creationDate = try? fileManager.attributesOfItem(atPath: fileURL.path)[.creationDate] as? Date,
                        creationDate.timeIntervalSinceNow < -1 { // si es más antiguo que el momento actual
                        do {
                            // Eliminar el archivo PDF
                            try fileManager.removeItem(at: fileURL)
                            print("Archivo PDF eliminado: \(fileURL.lastPathComponent)")
                            
                        } catch {
                            print("Error al eliminar el archivo PDF: \(error.localizedDescription)")
                        }
                    }
                }
            }
        }
    }
    

}

// Representación de un controlador de vista de selección de imágenes
struct ImagePicker: UIViewControllerRepresentable {
    // Enlace para almacenar las imágenes seleccionadas
    @Binding var selectedImages: [(UIImage, String)]
    
    // Método para crear el controlador de vista de selección de imágenes
    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.sourceType = .photoLibrary
        picker.delegate = context.coordinator
        return picker
    }
    
    // Método para actualizar el controlador de vista de selección de imágenes
    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}
    
    // Método para crear el coordinador
    func makeCoordinator() -> Coordinator {
        Coordinator(parent: self)
    }
    
    // Coordinador para manejar los eventos del selector de imágenes
    class Coordinator: NSObject, UINavigationControllerDelegate, UIImagePickerControllerDelegate {
        let parent: ImagePicker
        
        init(parent: ImagePicker) {
            self.parent = parent
        }
        
        // Método llamado cuando se selecciona una imagen
        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
            // Obtener la imagen seleccionada
            if let image = info[.originalImage] as? UIImage {
                // Obtener el nombre de archivo de la imagen
                let fileName = "Imagen seleccionada"
                
                // Actualizar el estado de las imágenes en el hilo principal
                DispatchQueue.main.async {
                    self.parent.selectedImages.append((image, fileName))
                }
            }
            
            // Cerrar el selector de imágenes
            picker.dismiss(animated: true)
        }
        
        // Método llamado cuando se cancela la selección
        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            // Cerrar el selector de imágenes
            picker.dismiss(animated: true)
        }
    }
}

// Vista previa de ContentView
struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}

