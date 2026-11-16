-- Yuyu-Yuang
-- Animation Detector v1.0

local Detector = {}

function Detector.Start(character)

    local humanoid = character:FindFirstChildOfClass("Humanoid")

    if not humanoid then
        warn("Humanoid tidak ditemukan!")
        return
    end

    local animator = humanoid:FindFirstChildOfClass("Animator")

    if not animator then
        warn("Animator tidak ditemukan!")
        return
    end

    print("[Yuyu-Yuang] Detector Aktif!")

    local connection = animator.AnimationPlayed:Connect(function(track)

        local animation = track.Animation

        if animation then
            print("ANIMATION DETECTED")
            print("Animation Name:", animation.Name)
            print("Animation ID:", animation.AnimationId)
        end

    end)

    return connection
end

return Detector
