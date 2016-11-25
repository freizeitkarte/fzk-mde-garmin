import java.nio.charset.Charset;
import java.util.Locale;

public class fzkJavaLocale {

	public static void main(String[] args) {
		
        System.out.println("Default Charset =   " + Charset.defaultCharset());
        System.out.println("file.encoding =     " + System.getProperty("file.encoding"));
		
		Locale currentLocale = Locale.getDefault();
 
        System.out.println("Language =          " + currentLocale.getLanguage());
        System.out.println("Country =           " + currentLocale.getCountry());

        System.out.println("User Country =      " + System.getProperty("user.language"));
        System.out.println("User Language =     " + System.getProperty("user.country"));
		
		System.out.println("Display Language =  " + currentLocale.getDisplayLanguage());
        System.out.println("Display Country =   " + currentLocale.getDisplayCountry());
 
		}
}
