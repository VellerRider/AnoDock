import SwiftUI

struct BoundaryDragExample: View {
    @State private var items = [
        DraggableItem(name: "Item 1"),
        DraggableItem(name: "Item 2"),
        DraggableItem(name: "Item 3")
    ]
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // 父视图背景
                Color.gray.opacity(0.2)
                    .ignoresSafeArea()
                
                // 子视图容器
                ForEach(items) { item in
                    DraggableItemView(item: item, items: $items, parentBounds: geometry.frame(in: .global))
                }
            }
        }
    }
}

struct DraggableItemView: View {
    let item: DraggableItem
    @Binding var items: [DraggableItem]
    let parentBounds: CGRect
    
    @State private var position: CGPoint = CGPoint(x: 150, y: 150)
    @State private var isOutsideBounds = false
    
    var body: some View {
        Text(item.name)
            .padding()
            .background(isOutsideBounds ? Color.red : Color.blue)
            .cornerRadius(8)
            .position(position)
            .gesture(
                DragGesture()
                    .onChanged { value in
                        position = value.location
                        // 检测是否超出范围
                        if !parentBounds.contains(value.location) {
                            isOutsideBounds = true
                        } else {
                            isOutsideBounds = false
                        }
                    }
                    .onEnded { _ in
                        // 如果超出范围，则从数据源删除
                        if isOutsideBounds {
                            withAnimation {
                                items.removeAll { $0.id == item.id }
                            }
                        }
                    }
            )
    }
}

struct DraggableItem: Identifiable {
    let id = UUID()
    var name: String
}

#Preview {
    BoundaryDragExample()
}
