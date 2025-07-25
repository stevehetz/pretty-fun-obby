# Trails

1. done - After a trail is purchased, it should equip
2. done - Setup shop gui to add/remove/buy trails
3. Create gamepass/shop images
4. Test with multiple players in real game
   1. leaving/joining
      1. making sure the PlayerTrails config in the controller is updating properly
   2. purchasing/equipping
      1. updating for all player's clients
   3. unequipping
      1. updating for all player's clients

Build the following into the shop gui:
Programmatically preview purchasable player trails using a ViewportFrame template. The script should:

- Clone a ViewportFrame template named “TrailPreviewTemplate” containing:
  - A Model named “PreviewModel”
  - A Part named “PreviewPart” with two Attachments (Front and Back)
  - A Trail instance parented to PreviewPart
  - A Camera and a DirectionalLight
- Parent the clone to the shop item’s GUI and set viewportFrame.CurrentCamera
- Accept a ColorSequence and a NumberSequence for trail.Color and trail.Transparency
- Configure the Trail’s ColorSequence and Transparency with those sequences
- Use RunService:BindToRenderStep to rotate PreviewPart in a circular path (radius = 2, speed = math.pi/2) so the trail renders in the ViewportFrame
- Clean up the RenderStep binding when the GUI is destroyed
