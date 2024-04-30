import SwiftUI
import PDFKit
import Photos

// Estructura que envuelve UIImage y hace que sea identificable
struct ImageItem: Identifiable {
    let id = UUID()
    let image: UIImage
}

struct ContentView: View {
    // Estado para almacenar las imágenes seleccionadas
    @State private var selectedImages: [(UIImage, String)] = []
    // Estado para controlar la presentación del selector de imágenes
    @State private var isShowingImagePicker = false
    @State private var selectedImageToShow: ImageItem? // Cambiar el tipo a ImageItem

    var body: some View {
        VStack {
            // Si hay imágenes seleccionadas
            if !selectedImages.isEmpty {
                // Muestra una lista con nombres de archivo y miniaturas de imágenes
                List(selectedImages.indices, id: \.self) { index in
                    let (_, fileName) = selectedImages[index]
                    let thumbnailSize = calculateThumbnailSize(for: selectedImages[index].0) // Usar la imagen en lugar de 'image'

                    HStack {
                        // Miniatura de la imagen como botón para mostrar en pantalla completa
                        Button(action: {
                            selectedImageToShow = ImageItem(image: selectedImages[index].0)
                        }) {
                            Image(uiImage: selectedImages[index].0)
                                .resizable()
                                .frame(width: thumbnailSize.width, height: thumbnailSize.height) // Usar tamaño calculado
                                .cornerRadius(5)
                        }


                        
                        // Texto descriptivo
                        Text(fileName)
                        
                        // Empujar el botón eliminar hacia la derecha
                        Spacer()
                        
                        // Botón de eliminar imagen
                        Button(action: {
                            // Eliminar la imagen seleccionada del arreglo
                            selectedImages.remove(at: index)
                        }) {
                            Image(systemName: "trash")
                                .foregroundColor(.white)
                        }
                        .buttonStyle(BorderlessButtonStyle()) // Evitar el resaltado de estilo de botón por defecto
                    }
                }
                .padding(.bottom) // Añadir espacio en la parte inferior de la lista
            }
            
            // Botón para abrir el selector de imágenes
            Button(action: {
                isShowingImagePicker.toggle()
            }) {
                Text("Añadir imágenes")
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
        .fullScreenCover(item: $selectedImageToShow) { selectedItem in
            let image = selectedItem.image
            // Vista de pantalla completa para mostrar la imagen seleccionada en detalle
            VStack {
                HStack {
                    Spacer()
                    Button(action: {
                        selectedImageToShow = nil // Cerrar la vista de pantalla completa al tocar el botón de "Cerrar"
                    }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.title)
                            .foregroundColor(.white)
                            .padding()
                    }
                    .padding(.top, UIApplication.shared.connectedScenes
                                            .compactMap { $0 as? UIWindowScene }
                                            .first?.windows
                                            .first?.windowScene?.statusBarManager?.statusBarFrame.height ?? 0)
                    .padding(.trailing) // Ajustar el espaciado del botón desde el borde derecho
                }
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .padding()
                Spacer()
            }
            .edgesIgnoringSafeArea(.all)
            .background(Color.black)
            .navigationBarHidden(true)
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

 
    
    // Función para calcular el tamaño de la miniatura manteniendo la relación de aspecto
    private func calculateThumbnailSize(for image: UIImage) -> CGSize {
        let maxWidth: CGFloat = 50 // Ancho máximo de la miniatura
        
        // Calcular el tamaño basado en la relación de aspecto original de la imagen
        let aspectRatio = image.size.width / image.size.height
        let thumbnailWidth = min(maxWidth, image.size.width) // Limitar el ancho máximo
        let thumbnailHeight = thumbnailWidth / aspectRatio
        
        return CGSize(width: thumbnailWidth, height: thumbnailHeight)
    }
    
    
    // Función para crear y compartir el PDF
    private func createAndSharePDF() {
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
                    print("antes de crear la instancia de actividad de compartir")
                    let activityViewController = UIActivityViewController(activityItems: [renamedPDFURL], applicationActivities: nil)
                    print("despues de crear la instancia de actividad de compartir")
                    // Presentar la actividad de compartir
                    print("antes del if de compartir")
                    if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
                       let window = windowScene.windows.first {
                        window.rootViewController?.present(activityViewController, animated: true, completion: nil)
                        print("dentro del if de compartir")
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
        print("entro a borrar archivos antiguos")
        deleteOldPDFs(in: temporaryDirectoryURL)
        print("salgo de borrar archivos antiguos")

        
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
                // Obtener el identificador local del PHAsset asociado con la imagen
                guard let assetIdentifier = info[.phAsset] as? PHAsset else {
                    // Si no se puede obtener el PHAsset, usar un nombre predeterminado
                    let fileName = "Imagen seleccionada"
                    DispatchQueue.main.async {
                        self.parent.selectedImages.append((image, fileName))
                    }
                    picker.dismiss(animated: true)
                    return
                }
                
                // Intentar obtener el nombre de archivo directamente del recurso de PHAsset
                if let resource = PHAssetResource.assetResources(for: assetIdentifier).first {
                    // Aquí obtenemos el nombre de archivo correspondiente a la imagen seleccionada
                    let fileName = resource.originalFilename
                    DispatchQueue.main.async {
                        self.parent.selectedImages.append((image, fileName))
                    }
                } else {
                    // Si no se puede obtener el nombre de archivo, usar un nombre predeterminado
                    let fileName = "Imagen seleccionada"
                    DispatchQueue.main.async {
                        self.parent.selectedImages.append((image, fileName))
                    }
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

