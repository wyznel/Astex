//
//  ModelManagementView.swift
//  Astex
//
//  Created by Ben Herbert on 25/06/2026.
//

import SwiftUI
import Ollama
import Textual



struct ModelManagementView: View {
    
    static var utilities = Utilities()
    
    @ObservedObject private var settings = Settings.shared
    
    @State private var models: [String] = []
    
    @State private var isSelected: Bool = false
    
    @State private var selectedModel: String? = Settings.shared.selectedModel
    
    @State private var size: String = "Loading..."
    
    var body: some View {
        VStack {
            InlineText(markdown: "**Models**")
                .padding(6)
///          Model List
            VStack(alignment: .leading){
                HStack {
                    Text("Model Name")
                        .frame(width: 150, alignment: .leading)
                    if !settings.showFormat || !settings.showParameterSize || !settings.showSizeOnDisk {
                        Spacer()
                    }
                    if settings.showSizeOnDisk {
                        Text("Size on disk")
                            .frame(width: 100, alignment: .leading)
                        Spacer()
                    }
                    if settings.showFormat {
                        Text("FORMAT")
                            .frame(width: 100, alignment: .leading)
                        Spacer()
                    }
                    if settings.showParameterSize {
                        Text("Parameter Size")
                            .frame(width: 100, alignment: .leading)
                    }
                    Spacer()
                    
                    Image(systemName: "trash")
                        .opacity(0)
                        .accessibilityHidden(true)
                    if !settings.showParameterSize {
                        Spacer()
                    }
                }
                .padding(.leading, 12)
                Divider()
                ForEach(models, id: \.self) { model in
                    ModelDetailsRow(
                        model: model,
                        selectedModel: $selectedModel
                    )
                    .padding(.top, 2)
                    Divider()
                }
            }
            .padding(.top, 15)
            .padding(.bottom, 15)
            .padding(.leading, 10)
            .padding(.trailing, 10)
            .frame(maxWidth: 600)
            .glassEffect(settings.glassEffect.interactive(), in: .rect(cornerRadius: 12))
            .onChange(of: selectedModel) {
                Settings.shared.selectedModel = selectedModel ?? ""
                print("Selected Model: \(Settings.shared.selectedModel)")
            }
            
            Button {
                settings.suppressModelDeletionConfirmation.toggle()
            } label: {
                Image(systemName: settings.suppressModelDeletionConfirmation ? "checkmark.square" : "cross")
            }
        }
        .task {
            models = await ModelManagementView.utilities.getAvailableModelsNAME_ONLY_OLLAMA()
        }
        .contentShape(Rectangle())
        .contextMenu(menuItems: {
            Button("Size on Disk", systemImage: settings.showSizeOnDisk ? "checkmark" : "square") {
                withAnimation(.spring(duration: settings.animationDelay)){
                    settings.showSizeOnDisk.toggle()
                }
            }
            
            Button("Format", systemImage: settings.showFormat ? "checkmark" : "square") {
                withAnimation(.spring(duration: settings.animationDelay)){
                    settings.showFormat.toggle()
                }
            }
            Button("Parameter Size", systemImage: settings.showParameterSize ? "checkmark" : "square") {
                withAnimation(.spring(duration: settings.animationDelay)){
                    settings.showParameterSize.toggle()
                }
            }
        })
    }
    
///  Combines ModelToggle and ModelInfo.
    struct ModelDetailsRow: View {
        let model: String
        
        @Binding var selectedModel: String?
        
        var body: some View {
            HStack{
                ModelToggle(
                    modelName: model,
                    selectedModel: $selectedModel
                )
                .frame(width: 150, alignment: .leading)
                
                Spacer()
                
                modelInfo(
                    modelName: model,
                    selectedModel: $selectedModel
                )
            }
            .padding(.leading, 12)
            .background(Color.sepiaAccent.opacity(selectedModel == model ? 0.1 : 0.0), in: RoundedRectangle(cornerRadius: 6))
            
        }
    }
/// Model Info Columns, linked with ModelToggle.
    struct modelInfo: View {
        let modelName: String
        
        @Binding var selectedModel: String?
        
        @ObservedObject private var settings = Settings.shared
        
        @State private var SIZE: String = ""
        @State private var FORMAT: String = ""
        @State private var PARAMETER_SIZE: String = ""
        
        @State private var isLoading: Bool = true
        @State private var isPresentingConfirm: Bool = false
        
        var body: some View {
            if isLoading {
                ProgressView()
                    .frame(width: 100, alignment: .leading)
                    .task {
                        let info = await ModelManagementView.utilities.getModelInfo(model: modelName)
                        let size_unrounded_gb = (info["size"] as! Double) / 1000000000
                        let size = Double(round(100 * size_unrounded_gb) / 100)
                        
                        let format = info["format"] as! String
                        let parameter_size = info["parameter_size"] as? String ?? "0"
                        
                        DispatchQueue.main.async {
                            self.SIZE = "\(size) GB"
                            self.FORMAT = format
                            self.PARAMETER_SIZE = parameter_size
                            self.isLoading = false
                        }
                    }
                Spacer()
                Text("")
                    .frame(width: 100, alignment: .leading)
                
            }
            else {
                if settings.showSizeOnDisk {
                    Text(SIZE)
                        .frame(width: 100, alignment: .leading)
                    Spacer()
                }
                if settings.showFormat {
                    Text(FORMAT)
                        .frame(width: 100, alignment: .leading)
                    Spacer()
                }
                if settings.showParameterSize {
                    Text(PARAMETER_SIZE)
                        .frame(width: 100, alignment: .leading)
                    Spacer()
                }
                
///             Delete model button.
                Button {
                    if !settings.suppressModelDeletionConfirmation {
                        isPresentingConfirm = true
                    }else {
                        print("Deleted model: \(modelName)")
                    }
                } label: {
                    Image(systemName: "trash")
                }
                .disabled(selectedModel == modelName)
                .confirmationDialog("Are you sure?", isPresented: $isPresentingConfirm) {
                    Button ("Delete model: \(modelName)", role: .destructive) {
                        print("Confirmation of deletion of model: \(modelName)")
                        isPresentingConfirm = false
                    }
                }
                .dialogIcon(Image(systemName: "trash.circle.fill"))
                .dialogSuppressionToggle(isSuppressed: settings.$suppressModelDeletionConfirmation)
            }
        }
    }
    
/// each model must have its own toggle (bars)
    struct ModelToggle: View {
        let modelName: String
        
        @State var isSelected: Bool = false
        
        @Binding var selectedModel: String?
        
        var body: some View {
            Toggle(
                modelName,
                isOn: Binding(
                    get: { selectedModel == modelName},
                    set: { isOn in
                        if isOn {
                            selectedModel = modelName
                            isSelected = true
                        }else if selectedModel == modelName {
                            selectedModel = nil
                        }
                    }
                )
            )
            .onChange(of: selectedModel){
                if selectedModel == modelName {
                    DispatchQueue.main.async {
                        isSelected = true
                    }
                }else{
                    isSelected = false
                }
            }
            .task{
                if selectedModel == modelName {
                    isSelected = true
                }
            }
            .disabled(isSelected)
            .frame(width: 150, alignment: .leading)
        }
    }
}
