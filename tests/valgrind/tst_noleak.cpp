#include <QtTest>
#include <QObject>


class SomeObject
{
public :
    SomeObject() {}

    int number() const { return 5; }

};

class NoLeakTest: public QObject
{
    Q_OBJECT

public:
    explicit NoLeakTest(QObject *parent = nullptr):
        QObject(parent)
    {
    }

private Q_SLOTS:
    void test();
};

void NoLeakTest::test()
{
    SomeObject *object = new SomeObject(); // Free the pointer -> no memory leak
    delete object;
}

QTEST_APPLESS_MAIN(NoLeakTest)

#include "tst_noleak.moc"
