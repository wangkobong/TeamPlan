//
//  ChallengeIconHelper.swift
//  teamplan
//
//  Created by sungyeon kim on 2023/12/28.
//  Copyright © 2023 team1os. All rights reserved.
//

import Foundation

struct ChallengeIconHelper {
    static func setIcon(type: ChallengeType, isLock: Bool, isComplete: Bool) -> String {
        if isLock {
            return "lock_icon"
        } else {
            switch type {
            case .onboarding: // 온보딩
                return isComplete ? "book_circle_blue" : "book_circle_grey"
            case .serviceTerm: // 서비스 사용 기간
                return isComplete ? "calendar_circle_blue" : "calendar_circle_grey"
            case .totalTodo: // 등록 개수
                return isComplete ? "pencil_circle_blue" : "pencil_circle_grey"
            case .projectAlert: // 프로젝트 등록
                return isComplete ? "folder_circle_plus_blue" : "folder_circle_plus_grey"
            case .projectFinish: // 프로젝트 해결
                return isComplete ? "folder_circle_check_blue" : "folder_circle_check_grey"
            case .waterDrop: // 물방울 개수
                return isComplete ? "drop_circle_blue" : "drop_circle_grey"
            case .unknownType:
                return isComplete ? "book_circle_blue" : "book_circle_grey"
            }
        }
    }
}
