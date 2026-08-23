# Depression in Students

## Abstract

with the ever increasing mental health issues among younger generations as technology is adopted into society
there is an issue of traditional counseling becoming a foreign concept to younger students who require help
the capability of students to feel comfortable in a traditional setting decreases while the usage of technology increases

this article seeks to create a bridge between the necessity of gathering data from in person, therapeutic, conversations
by both analysis and showing of usefulness
analyzing existing depression data to gather insights about how to best treat students as well as what issues may cause the most problems for them
and then providing insight into how machine learning models may be used to create systems of mental health for the students 

these challenges include both in depth analysis of the existing dataset as to gain insight on what aspects of a students life are most difficult
the views of why these challenges may be the most impactful on a students life
as well as the necessity to find ways to incorporate efficient models into how a student lives

## Content

depression in students can occur by a multitude of ways.
the investigation into what causes depression is best done in a clinical setting.
however finding the stressors of a students life is difficult due to the sheer number of possibilities.
further analysis of a student is necessary in treatment plans
and the stressors indexed by the intakes may not cover the entirety of the wellbeing roadmap

this article seeks to further investigate essential areas of a students life to glean insight into what causes depression.
the major areas include financials, academic performance, age, and a look at the data driven aspects of a students lifestyle.
we hope that it may provide insight into how to treat a student by eliminating or decreasing the extreme stressors in their life.
treatment plans for students vary, and are mentioned breifly in the conclusion of this article,

after initially inspecting the dataset a few hypothesised observations were presented

- younger students higher levels of [depression, academic pressure, financial stress]
- academic pressure increases with financial stress and study hours
- study satisfaction decreases with increased academic pressure
- higher performing students feel increased academic pressure
- younger students have a higher cumulative gpa
- signs of depression increase with financial stress

these observations were heuristic based and were further analyzed in these preceedings

we were able to observe high correlation based off the initial dataset between both reported academic pressure and financial stress,
indicating that depression was closely linked to the precense of stressors rather than the absence of positives.
we believe this supports the idea that depression is connected to a feeling of helplessness is the current situtation.

after further analysis of the relationship between academic pressure and financial stress we saw the greatest concentration of depressive symptoms when both were present
we then dove into observations between hours spent sleeping, working, and studying a term we have dubbed lifestyle
finding that the more depressed students slept longer and studied more, this led to the idea that these students
cyclically focused all their time and energy on studying because they felt trapped in their current situtation

in order to assist with students in future years and machine learning model was created 
by plotting the lifestyle of the students and adding a special kernel function of those two variables we were able to create a 
machine learning model with accuracy for predicting depression of 62% which is a decent result for only having included of the less correlated metrics

further analysis lead to bringing in academics and financial stressors in creation of a new model, which incorporated these two metrics
bringing in a stacking classifier to split the data for analysis before making a final logistic classification 
by splitting the data we are able to train the model using different approaches that best describe the dataset features 
and after classification on our testing dataset we acheieved an accuracy score of 78% much better performing

a consideration found in the behavior of the model is that financial stress is a major contributor to the prediction of depression in a student,
this makes sense with our working theory of being trapped as it is opinionatedly the most difficult of our feature set to change,
however we have noticed that in the presence of extreme financial stress, a rating of four or five on a five point scale,
the lifestyle aspects are not as important, it is essentially the pressure of financial stress that drives depressive symptoms

we are now able to use this model in an automated system to monitor student health and potentially catch the warning signs of depression
before they reach problematic stages, we are also able to make recommendations on a students well being by finding compromise 
between what and how to change different aspects of their lifestyle, for instance lowering sleep from 12 hours to 8 or 
seeking to study more effectively based on their learning styles rather than spend more time going over the materials

we hope that in the future student activity is more readily available and that the capacity to assist is made clear,
creating machine learning models to observe wellness of an individual will greatly improve therapy or journaling applications,
we hope to continue this research into the domain of language recognition in order to augment journaling systems with artificial intelligence
giving better insight about how a student is progressing psychologically as a more private assistive alternative to traditional counseling

this would provide students with suggestions as to how to improve their mental health status on top of gathering the data,
it is easy to feel as though you are being data mined online but for no benefit to yourself other than the service you are using
this would provide little to no lifelong benefit and we seek to change that to make it so the data you provide to these services
is immediately useful to yourself and allows you to track your progress along the way bringing incremental change to the forefront of building success

## Citations


