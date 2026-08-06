# coki schd

prei ;; pre-emptive intake calories 
  rati ([(fats, [15,30]),..] /: 100gm                            ;; ratio of macronutrients
  carb ([30,60]gm /: hour exer :: post exer reup <= [15,30]tm)   ;; ?simple or complex? carbohydrates 
  amac ([??,??]gm /: hour exer :: post exer reup <= [00,60]tm)   ;; amino acid schedule 
  aqua ([??,??]vm /: hour exer :: post exer reup <= [<:,:>]tm)   ;; replace water as needed, thermo regulation importatant during exertion
  rngi ([(1.25, 1.5) | (1.5, 1.75) | (1.75, 2) | 2, 2.5)])       ;; pounds per person per day recommended ranges, 1lbs=0.453592kilogram
  kcal ([25,30]00 kcal /: body (appx 454g /: unit) :: [00,24)td) ;; calories needed per day (technical cal versus Cal)
