//
//  RenderingMode.swift
//  
//
//  Created by Max Kuznetsov on 08.08.2022.
//

import Foundation

public enum RenderingMode {
    case renderInContext // oldschool view.layer.render(in: ctx.cgContext)
    case snapshot(afterScreenUpdates: Bool)
    case drawHierarchy(afterScreenUpdates: Bool) //view.drawHierarchy(in: view.bounds, afterScreenUpdates: )
}
