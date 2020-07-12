// Boost
#include <boost/program_options.hpp>

namespace po = boost::program_options;

// Custom
#include <dvReadImageIOBase.h>
#include <dvResampleVolume.h>

int
main(int argc, char* argv[])
{

  // Declare the supported options.
  po::options_description description("Allowed options");
  description.add_options()("help", "Print usage information.")
                           ("input-image", po::value<std::string>()->required(), "Filename of input image.")
                           ("output-image", po::value<std::string>()->required(), "Filename of output image.")
                           ("spacing", po::value<double>()->default_value(0), "Desired spacing.")
                           ("spacingx", po::value<double>()->default_value(0), "Desired spacing for x-axis.")
                           ("spacingy", po::value<double>()->default_value(0), "Desired spacing for y-axis.")
                           ("spacingz", po::value<double>()->default_value(0), "Desired spacing for z-axis.")
                           ("dimx", po::value<int>()->default_value(0), "Desired x output dimension")
                           ("dimy", po::value<int>()->default_value(0), "Desired x output dimension")
                           ("dimz", po::value<int>()->default_value(0), "Desired x output dimension")
                           ("target-size-image", po::value<std::string>()->default_value(""), "Image with desired dimensions of output-image")
                           ("interpolator", po::value<unsigned int>()->default_value(1),"Order of BSpline interpolation (0 to 5 allowed).");

  po::variables_map vm;
  po::store(po::parse_command_line(argc, argv, description), vm);

  if (vm.count("help") || 1 == argc) {
    std::cout << description << '\n';
    return EXIT_SUCCESS;
  }

  po::notify(vm);

  const std::string IImage = vm["input-image"].as<std::string>();
  const std::string OImage = vm["output-image"].as<std::string>();
  const double spacing = vm["spacing"].as<double>();
  const double spacingx = vm["spacingx"].as<double>();
  const double spacingy = vm["spacingy"].as<double>();
  const double spacingz = vm["spacingz"].as<double>();
  const int dimx = vm["dimx"].as<int>();
  const int dimy = vm["dimy"].as<int>();
  const int dimz = vm["dimz"].as<int>();
  const std::string OImage_target = vm["target-size-image"].as<std::string>();
  const unsigned int interpolator = vm["interpolator"].as<unsigned int>();

  switch (dv::ReadImageIOBase(IImage)->GetComponentType()) {
    case itk::ImageIOBase::UCHAR:
      dv::ResampleVolume<3, unsigned char>(
        IImage, OImage, spacing, spacingx, spacingy, spacingz, dimx, dimy, dimz, OImage_target, interpolator);
      break;
    case itk::ImageIOBase::CHAR:
      dv::ResampleVolume<3, char>(IImage, OImage, spacing, spacingx, spacingy, spacingz, dimx, dimy, dimz, OImage_target, interpolator);
      break;
    case itk::ImageIOBase::USHORT:
      dv::ResampleVolume<3, unsigned short>(
        IImage, OImage, spacing, spacingx, spacingy, spacingz, dimx, dimy, dimz, OImage_target, interpolator);
      break;
    case itk::ImageIOBase::SHORT:
      dv::ResampleVolume<3, short>(IImage, OImage, spacing, spacingx, spacingy, spacingz, dimx, dimy, dimz, OImage_target, interpolator);
      break;
    case itk::ImageIOBase::UINT:
      dv::ResampleVolume<3, unsigned int>(
        IImage, OImage, spacing, spacingx, spacingy, spacingz, dimx, dimy, dimz, OImage_target, interpolator);
      break;
    case itk::ImageIOBase::INT:
      dv::ResampleVolume<3, int>(IImage, OImage, spacing, spacingx, spacingy, spacingz, dimx, dimy, dimz, OImage_target, interpolator);
      break;
    case itk::ImageIOBase::ULONG:
      dv::ResampleVolume<3, unsigned long>(
        IImage, OImage, spacing, spacingx, spacingy, spacingz, dimx, dimy, dimz, OImage_target, interpolator);
      break;
    case itk::ImageIOBase::LONG:
      dv::ResampleVolume<3, long>(IImage, OImage, spacing, spacingx, spacingy, spacingz, dimx, dimy, dimz, OImage_target, interpolator);
      break;
    case itk::ImageIOBase::FLOAT:
      dv::ResampleVolume<3, float>(IImage, OImage, spacing, spacingx, spacingy, spacingz, dimx, dimy, dimz, OImage_target, interpolator);
      break;
    case itk::ImageIOBase::DOUBLE:
      dv::ResampleVolume<3, double>(IImage, OImage, spacing, spacingx, spacingy, spacingz, dimx, dimy, dimz, OImage_target, interpolator);
      break;
    default:
      std::cerr << "ERROR: Unrecognized pixel type." << std::endl;
      return EXIT_FAILURE;
      break;
  }

  return EXIT_SUCCESS;
}


