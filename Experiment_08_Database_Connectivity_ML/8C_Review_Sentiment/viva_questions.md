# Viva questions - 8C_Review_Sentiment

**Q1. What is TF-IDF?** Term frequency x inverse document frequency: words frequent in a review but rare across reviews get a high weight.

**Q2. Why Multinomial Naive Bayes for text?** It models word counts/weights per class with the 'naive' independence assumption; fast and strong baseline for small text data.

**Q3. How do you read a confusion matrix?** Rows = true class, columns = predicted class; the diagonal is correct predictions.

**Q4. Why remove stop words and punctuation?** They carry little sentiment and inflate the vocabulary.

**Q5. Why label from rating?** Distant supervision: the star rating is a free label for the review text.

**Q6. What is the risk of the tiny data set?** Accuracy varies a lot with the split; the 5-review test set is only illustrative.

**Q7. What does `$text` need?** A text index on the field; stemming and stop-word handling are language specific.
